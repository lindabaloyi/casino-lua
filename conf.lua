return {
    identity = "Casino",
    version = "1.0.0",
    console = true,
    window = {
        title = "Casino",
        width = 896,
        height = 414,
        resizable = false,
        fullscreen = false
    },
    modules = {
        ["src.GameState"] = true,
        ["src.ScreenManager"] = true,
        ["src.ui.Button"] = true,
        ["src.ui.HomeScreen"] = true,
        ["src.ui.GameBoard"] = true,
        ["src.ui.layout.LayoutConfig"] = true,
        ["src.ui.layout.PositionCalculator"] = true,
        ["src.ui.drag.DragState"] = true,
        ["src.ui.input.HitDetector"] = true,
        ["src.ui.input.CollisionDetector"] = true,
        ["src.ui.input.InputHandler"] = true,
        ["src.ui.render.BoardRenderer"] = true,
        ["src.shared.actions.trail"] = true,
        ["src.shared.actions.createTemp"] = true,
        ["src.shared.actions.capture"] = true,
        ["src.shared.actions.captureOwn"] = true,
        ["src.shared.actions.acceptTemp"] = true
    }
}