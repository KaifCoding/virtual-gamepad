using System.Net;
using System.Net.Sockets;
using System.Text;
using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;

namespace VirtualGamepadHost;

public sealed class GamepadServer : IDisposable
{
    private sealed class ClientSession
    {
        public required IXbox360Controller Controller { get; init; }
        public required string DeviceName { get; set; }
        public DateTime LastSeenUtc { get; set; } = DateTime.UtcNow;
    }

    private readonly ViGEmClient _viGem;
    private readonly UdpClient _socket;
    private readonly Dictionary<IPEndPoint, ClientSession> _clients = new();
    private readonly string _hostName = Environment.MachineName;
    private CancellationTokenSource? _cts;

    public event Action<string>? Log;
    public event Action<int>? ClientCountChanged;

    public GamepadServer()
    {
        _viGem = new ViGEmClient();
        _socket = new UdpClient();
        _socket.Client.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, true);
        _socket.Client.Bind(new IPEndPoint(IPAddress.Any, Protocol.Port));
        _socket.EnableBroadcast = true;
    }

    public void Start()
    {
        _cts = new CancellationTokenSource();
        _ = ReceiveLoopAsync(_cts.Token);
        _ = TimeoutLoopAsync(_cts.Token);
        Log?.Invoke($"Listening on UDP port {Protocol.Port}. Waiting for phones to connect...");
    }

    private async Task ReceiveLoopAsync(CancellationToken token)
    {
        while (!token.IsCancellationRequested)
        {
            UdpReceiveResult result;
            try
            {
                result = await _socket.ReceiveAsync(token);
            }
            catch (OperationCanceledException)
            {
                return;
            }
            catch (SocketException)
            {
                continue;
            }

            try
            {
                HandlePacket(result.Buffer, result.RemoteEndPoint);
            }
            catch (Exception ex)
            {
                Log?.Invoke($"Error handling packet from {result.RemoteEndPoint}: {ex.Message}");
            }
        }
    }

    private void HandlePacket(byte[] data, IPEndPoint sender)
    {
        if (data.Length < 2 || data[0] != Protocol.Magic) return;
        byte type = data[1];

        switch (type)
        {
            case Protocol.TypeDiscover:
                Log?.Invoke($"Discovery request from {sender}");
                SendDiscoverResponse(sender);
                break;

            case Protocol.TypeHello:
                HandleHello(data, sender);
                break;

            case Protocol.TypeInput:
                HandleInput(data, sender);
                break;

            case Protocol.TypeHeartbeat:
                Touch(sender);
                break;

            case Protocol.TypeGoodbye:
                RemoveClient(sender, "disconnected");
                break;
        }
    }

    private void SendDiscoverResponse(IPEndPoint sender)
    {
        var nameBytes = Encoding.UTF8.GetBytes(_hostName);
        var packet = new byte[3 + nameBytes.Length];
        packet[0] = Protocol.Magic;
        packet[1] = Protocol.TypeDiscoverResponse;
        packet[2] = (byte)nameBytes.Length;
        Array.Copy(nameBytes, 0, packet, 3, nameBytes.Length);
        _socket.Send(packet, packet.Length, sender);
    }

    private void HandleHello(byte[] data, IPEndPoint sender)
    {
        string deviceName = "Unknown device";
        if (data.Length >= 3)
        {
            int nameLen = data[2];
            if (data.Length >= 3 + nameLen)
                deviceName = Encoding.UTF8.GetString(data, 3, nameLen);
        }

        bool ok = true;
        if (!_clients.TryGetValue(sender, out var session))
        {
            try
            {
                var controller = _viGem.CreateXbox360Controller();
                controller.Connect();
                session = new ClientSession { Controller = controller, DeviceName = deviceName };
                _clients[sender] = session;
                Log?.Invoke($"Connected: {deviceName} ({sender})");
                ClientCountChanged?.Invoke(_clients.Count);
            }
            catch (Exception ex)
            {
                ok = false;
                Log?.Invoke($"Failed to create virtual controller for {sender}: {ex.Message}. " +
                            "Is ViGEmBus installed? See README.");
            }
        }
        else
        {
            session.DeviceName = deviceName;
        }

        Touch(sender);

        var ack = new byte[3];
        ack[0] = Protocol.Magic;
        ack[1] = Protocol.TypeHelloAck;
        ack[2] = (byte)(ok ? 1 : 0);
        _socket.Send(ack, ack.Length, sender);
    }

    private void HandleInput(byte[] data, IPEndPoint sender)
    {
        if (data.Length < 18) return;
        if (!_clients.TryGetValue(sender, out var session))
        {
            // Client is streaming input without having completed HELLO
            // (e.g. our ACK was lost) - treat this first INPUT as an
            // implicit HELLO so the experience is still seamless.
            HandleHello(new byte[] { Protocol.Magic, Protocol.TypeHello }, sender);
            if (!_clients.TryGetValue(sender, out session)) return;
        }

        ushort buttons = BitConverter.ToUInt16(data, 2);
        short lx = BitConverter.ToInt16(data, 4);
        short ly = BitConverter.ToInt16(data, 6);
        short rx = BitConverter.ToInt16(data, 8);
        short ry = BitConverter.ToInt16(data, 10);
        byte lt = data[12];
        byte rt = data[13];
        uint seq = BitConverter.ToUInt32(data, 14);

        var state = new GamepadInputState
        {
            Buttons = buttons,
            Lx = lx,
            Ly = ly,
            Rx = rx,
            Ry = ry,
            Lt = lt,
            Rt = rt,
            Sequence = seq
        };

        XInputMapper.Apply(session.Controller, state);
        session.LastSeenUtc = DateTime.UtcNow;
    }

    private void Touch(IPEndPoint sender)
    {
        if (_clients.TryGetValue(sender, out var session))
            session.LastSeenUtc = DateTime.UtcNow;
    }

    private void RemoveClient(IPEndPoint endpoint, string reason)
    {
        if (_clients.TryGetValue(endpoint, out var session))
        {
            try
            {
                XInputMapper.Reset(session.Controller);
                session.Controller.Disconnect();
            }
            catch
            {
                /* already gone */
            }

            _clients.Remove(endpoint);
            Log?.Invoke($"Removed {session.DeviceName} ({endpoint}) - {reason}");
            ClientCountChanged?.Invoke(_clients.Count);
        }
    }

    private async Task TimeoutLoopAsync(CancellationToken token)
    {
        while (!token.IsCancellationRequested)
        {
            await Task.Delay(1000, token).ContinueWith(_ => { });
            if (token.IsCancellationRequested) break;

            var cutoff = DateTime.UtcNow.AddMilliseconds(-Protocol.ClientTimeoutMs);
            foreach (var endpoint in _clients.Where(kv => kv.Value.LastSeenUtc < cutoff)
                         .Select(kv => kv.Key).ToList())
            {
                RemoveClient(endpoint, "timed out");
            }
        }
    }

    public void Dispose()
    {
        _cts?.Cancel();
        foreach (var endpoint in _clients.Keys.ToList())
            RemoveClient(endpoint, "server shutting down");
        _socket.Dispose();
        _viGem.Dispose();
    }
}
