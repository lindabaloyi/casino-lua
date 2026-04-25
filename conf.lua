return {
    identity = "Casino",
    version = "1.0.0",
    console = false,
    window = {
        title = "Casino",
        width = 640,
        height = 360,
        resizable = false,
        fullscreen = false
    },
    modules = {
        ["src.GameState"] = true,
        ["src.ScreenManager"] = true,
        ["src.ui.Button"] = true,
        ["src.ui.HomeScreen"] = true,
        ["src.ui.GameScreen"] = true
    }
}