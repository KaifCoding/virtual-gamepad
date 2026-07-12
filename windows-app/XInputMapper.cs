using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;

namespace VirtualGamepadHost;

/// <summary>
/// Applies a GamepadInputState onto an IXbox360Controller. Isolated in its
/// own class so the UDP/session code doesn't need to know about ViGEm types.
/// </summary>
public static class XInputMapper
{
    public static void Apply(IXbox360Controller controller, GamepadInputState state)
    {
        controller.SetButtonState(Xbox360Button.A, state.Button(Protocol.BitA));
        controller.SetButtonState(Xbox360Button.B, state.Button(Protocol.BitB));
        controller.SetButtonState(Xbox360Button.X, state.Button(Protocol.BitX));
        controller.SetButtonState(Xbox360Button.Y, state.Button(Protocol.BitY));
        controller.SetButtonState(Xbox360Button.LeftShoulder, state.Button(Protocol.BitLb));
        controller.SetButtonState(Xbox360Button.RightShoulder, state.Button(Protocol.BitRb));
        controller.SetButtonState(Xbox360Button.LeftThumb, state.Button(Protocol.BitLsClick));
        controller.SetButtonState(Xbox360Button.RightThumb, state.Button(Protocol.BitRsClick));
        controller.SetButtonState(Xbox360Button.Start, state.Button(Protocol.BitStart));
        controller.SetButtonState(Xbox360Button.Back, state.Button(Protocol.BitBack));
        controller.SetButtonState(Xbox360Button.Guide, state.Button(Protocol.BitGuide));
        controller.SetButtonState(Xbox360Button.Up, state.Button(Protocol.BitDpadUp));
        controller.SetButtonState(Xbox360Button.Down, state.Button(Protocol.BitDpadDown));
        controller.SetButtonState(Xbox360Button.Left, state.Button(Protocol.BitDpadLeft));
        controller.SetButtonState(Xbox360Button.Right, state.Button(Protocol.BitDpadRight));

        controller.SetAxisValue(Xbox360Axis.LeftThumbX, state.Lx);
        controller.SetAxisValue(Xbox360Axis.LeftThumbY, state.Ly);
        controller.SetAxisValue(Xbox360Axis.RightThumbX, state.Rx);
        controller.SetAxisValue(Xbox360Axis.RightThumbY, state.Ry);

        controller.SetSliderValue(Xbox360Slider.LeftTrigger, state.Lt);
        controller.SetSliderValue(Xbox360Slider.RightTrigger, state.Rt);

        controller.SubmitReport();
    }

    /// <summary>Neutral/rest state, used right before a client disconnects.</summary>
    public static void Reset(IXbox360Controller controller)
    {
        foreach (var button in new[]
                 {
                     Xbox360Button.A, Xbox360Button.B, Xbox360Button.X, Xbox360Button.Y,
                     Xbox360Button.LeftShoulder, Xbox360Button.RightShoulder,
                     Xbox360Button.LeftThumb, Xbox360Button.RightThumb,
                     Xbox360Button.Start, Xbox360Button.Back, Xbox360Button.Guide,
                     Xbox360Button.Up, Xbox360Button.Down, Xbox360Button.Left, Xbox360Button.Right
                 })
        {
            controller.SetButtonState(button, false);
        }

        controller.SetAxisValue(Xbox360Axis.LeftThumbX, 0);
        controller.SetAxisValue(Xbox360Axis.LeftThumbY, 0);
        controller.SetAxisValue(Xbox360Axis.RightThumbX, 0);
        controller.SetAxisValue(Xbox360Axis.RightThumbY, 0);
        controller.SetSliderValue(Xbox360Slider.LeftTrigger, 0);
        controller.SetSliderValue(Xbox360Slider.RightTrigger, 0);
        controller.SubmitReport();
    }
}
