import Foundation

#if os(Windows)
import WinSDK
#endif

// from https://github.com/vapor/console-kit/blob/4.15.2/Sources/ConsoleKitTerminal/Terminal/Terminal.swift#L142
func terminalSize() -> (width: Int, height: Int) {
#if os(Windows)
	var csbi = CONSOLE_SCREEN_BUFFER_INFO()
	GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &csbi)
	return (Int(csbi.dwSize.X), Int(csbi.dwSize.Y))
#else
	var w = winsize()
	_ = ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w);
	return (Int(w.ws_col), Int(w.ws_row))
#endif
}
