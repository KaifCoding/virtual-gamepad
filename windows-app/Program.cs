using System.Net;
using System.Net.Sockets;
using VirtualGamepadHost;

Console.WriteLine("=======================================");
Console.WriteLine("  Virtual Gamepad Host");
Console.WriteLine("=======================================");
Console.WriteLine();

var localIps = GetLocalIPv4Addresses();
if (localIps.Count == 0)
{
    Console.WriteLine("Could not find a local network IP address. Make sure you're connected to WiFi/LAN.");
}
else
{
    Console.WriteLine("Enter one of these addresses in the phone app (WiFi must be on the same network):");
    foreach (var ip in localIps)
        Console.WriteLine($"    {ip}   (port {Protocol.Port})");
    Console.WriteLine();
    Console.WriteLine("Or just tap \"Auto-discover\" in the app - it will find this PC automatically.");
}

Console.WriteLine();

GamepadServer server;
try
{
    server = new GamepadServer();
}
catch (Exception ex)
{
    Console.WriteLine("Failed to start: " + ex.Message);
    Console.WriteLine();
    Console.WriteLine("This usually means the ViGEmBus driver isn't installed.");
    Console.WriteLine("Download and install it from:");
    Console.WriteLine("  https://github.com/ViGEm/ViGEmBus/releases/latest");
    Console.WriteLine("then run this app again.");
    Console.WriteLine();
    Console.WriteLine("Press Enter to exit.");
    Console.ReadLine();
    return;
}

server.Log += msg => Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] {msg}");
server.ClientCountChanged += count => Console.WriteLine($"[{DateTime.Now:HH:mm:ss}] Connected controllers: {count}");
server.Start();

Console.WriteLine("Server running. Press Ctrl+C or close this window to stop.");
var exitEvent = new ManualResetEvent(false);
Console.CancelKeyPress += (_, e) =>
{
    e.Cancel = true;
    exitEvent.Set();
};
AppDomain.CurrentDomain.ProcessExit += (_, _) => server.Dispose();
exitEvent.WaitOne();
server.Dispose();
return;

static List<string> GetLocalIPv4Addresses()
{
    var result = new List<string>();
    foreach (var ni in NetworkInterface_GetAllUp())
    {
        foreach (var addr in ni)
        {
            if (addr.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(addr))
                result.Add(addr.ToString());
        }
    }
    return result;
}

static IEnumerable<List<IPAddress>> NetworkInterface_GetAllUp()
{
    foreach (var ni in System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces())
    {
        if (ni.OperationalStatus != System.Net.NetworkInformation.OperationalStatus.Up) continue;
        if (ni.NetworkInterfaceType == System.Net.NetworkInformation.NetworkInterfaceType.Loopback) continue;
        yield return ni.GetIPProperties().UnicastAddresses.Select(a => a.Address).ToList();
    }
}
