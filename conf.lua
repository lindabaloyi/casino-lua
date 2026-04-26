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
        ["src.shared.actions.trail"] = true
    }
}