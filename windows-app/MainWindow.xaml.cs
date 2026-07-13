using System.Collections.ObjectModel;
using System.Diagnostics;
using System.Net;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Windows;
using System.Windows.Input;
using System.Windows.Navigation;

namespace VirtualGamepadHost;

public partial class MainWindow : Window
{
    private GamepadServer? _server;
    private readonly ObservableCollection<string> _logLines = new();
    private bool _logVisible;

    public MainWindow()
    {
        InitializeComponent();
        LogList.ItemsSource = _logLines;
        Loaded += MainWindow_Loaded;
        Closing += (_, _) => _server?.Dispose();
    }

    private void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        var addresses = GetLocalIPv4Addresses();
        AddressText.Text = addresses.Count == 0
            ? "Could not detect a local IP - check your WiFi/LAN connection"
            : string.Join("   or   ", addresses.Select(a => $"{a}  (port {Protocol.Port})"));

        try
        {
            _server = new GamepadServer();
        }
        catch (Exception ex)
        {
            AddressText.Text = "Failed to start - ViGEmBus driver not found";
            AddressText.Foreground = System.Windows.Media.Brushes.Crimson;
            AppendLog($"Startup error: {ex.Message}");
            AppendLog("Install ViGEmBus from https://github.com/ViGEm/ViGEmBus/releases/latest, then restart.");
            _logVisible = true;
            LogScroll.Visibility = Visibility.Visible;
            ToggleLogButton.Content = "Hide connection log";
            return;
        }

        _server.Log += msg => Dispatcher.Invoke(() => AppendLog(msg));
        _server.ClientCountChanged += count => Dispatcher.Invoke(() =>
            ConnectedCountText.Text = $"Connected Device : {count}");
        _server.Start();
        AppendLog("Server started. Waiting for phones to connect...");
    }

    private void AppendLog(string message)
    {
        _logLines.Add($"[{DateTime.Now:HH:mm:ss}] {message}");
        if (_logLines.Count > 200) _logLines.RemoveAt(0);
        if (LogScroll.Visibility == Visibility.Visible)
            LogScroll.ScrollToEnd();
    }

    private void ToggleLog_Click(object sender, RoutedEventArgs e)
    {
        _logVisible = !_logVisible;
        LogScroll.Visibility = _logVisible ? Visibility.Visible : Visibility.Collapsed;
        ToggleLogButton.Content = _logVisible ? "Hide connection log" : "Show connection log";
    }

    private void TitleBar_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ClickCount == 2)
        {
            MaximizeRestore_Click(sender, e);
            return;
        }
        if (e.ButtonState == MouseButtonState.Pressed) DragMove();
    }

    private void Minimize_Click(object sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void MaximizeRestore_Click(object sender, RoutedEventArgs e)
    {
        WindowState = WindowState == WindowState.Maximized ? WindowState.Normal : WindowState.Maximized;
    }

    private void Close_Click(object sender, RoutedEventArgs e) => Close();

    private void Hyperlink_RequestNavigate(object sender, RequestNavigateEventArgs e)
    {
        Process.Start(new ProcessStartInfo(e.Uri.AbsoluteUri) { UseShellExecute = true });
        e.Handled = true;
    }

    private static List<string> GetLocalIPv4Addresses()
    {
        var result = new List<string>();
        foreach (var ni in NetworkInterface.GetAllNetworkInterfaces())
        {
            if (ni.OperationalStatus != OperationalStatus.Up) continue;
            if (ni.NetworkInterfaceType == NetworkInterfaceType.Loopback) continue;

            foreach (var addr in ni.GetIPProperties().UnicastAddresses)
            {
                if (addr.Address.AddressFamily == AddressFamily.InterNetwork && !IPAddress.IsLoopback(addr.Address))
                    result.Add(addr.Address.ToString());
            }
        }
        return result;
    }
}
