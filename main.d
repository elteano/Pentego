import game;
import ncs.ncurses;
import std.stdio;

private:
WINDOW *capwin;
WINDOW *boardwin;
int ROWS, COLUMNS;
bool endLoop = false;	//When this is true, the function loop() exits.
Game g;
public:
//immutable keyword is similar to 'final' in Java
///Constant that contains the board width.
immutable BOARD_WIDTH = 19;
///Constant that contains the board height.
immutable BOARD_HEIGHT = 19;
///Constant that contains the scoreboard width.
///Scoreboard height is the same as BOARD_HEIGHT.
immutable SCORE_WIDTH = 4;

//enum type is similar to a class that only contains basic values.
///Keeps track of the foreground/background color pairs.
enum Colors {
	PLAYER_ONE = 1,
	PLAYER_TWO,
	COLOR_DEFAULT
}

//public static void main in Java
///Main method.  Initializes curses window and runs game.
void main(string[] args) {	//string is similar to String
	//Prepare terminal for text printing
	initscr();
	refresh();			//Get the display ready
	getmaxyx(stdscr, ROWS, COLUMNS);
	if (ROWS < BOARD_HEIGHT || COLUMNS < BOARD_WIDTH + SCORE_WIDTH) {
		cleanup();
		writef("Please use a screen size of at least %dx%d.",
			BOARD_WIDTH+SCORE_WIDTH, BOARD_HEIGHT);
		return;
	}
	setup_color();	//Prepare colors
	g = new Game(BOARD_WIDTH, BOARD_HEIGHT);
	init_windows();
	//cbreak(); //Characters go straight to interpretation
	raw();	//Same as cbreak, but also goes for ^C, etc.
	noecho();	//Characters aren't echoed at cursor
	keypad(stdscr, true);	//Arrow keys, etc. are listened
	//refresh();
	//printBoard();
	//wrefresh(boardwin);
	loop();
	cleanup();
}

void loop() {
	printBoard();	//This can't be down there, stops cursor movement x.x
	wmove(boardwin, BOARD_HEIGHT / 2, BOARD_WIDTH / 2);
	updateScores();
	refresh();
	wrefresh(boardwin);
	buh:
	while(!endLoop) {
		int ch = getch();
		int x, y;
		getyx(boardwin, y, x);
		final switch (ch) {
			case KEY_LEFT:
				wmove(boardwin, y, x-1);
				break;
			case KEY_RIGHT:
				wmove(boardwin, y, x+1);
				break;
			case KEY_UP:
				wmove(boardwin, y-1, x);
				break;
			case KEY_DOWN:
				wmove(boardwin, y+1, x);
				break;
			case ' ':
				g.playPiece(x, y);
				printBoard();
				wmove(boardwin, y, x);
				break;
			case 'r':
				printBoard();
				refresh();
				wrefresh(boardwin);
				break;
			case 'n':
				if (g.pass() == 1 && doScoreThing())
					return;
				break;
			case 'q':
				break buh;
		}
		updateScores();
		refresh();
		wrefresh(boardwin);
		version (pente) {
			if (doScoreThing())
				return;
		}
	}
}

bool doScoreThing() {
	int v = g.getVictor();
	if (v >= 0) {
		attron(COLOR_PAIR(v+1));
		printw("Player %d wins!", v);
		getch();
		return true;
	}
	else if (v == -3) {
		printw("The game is tied!");
		getch();
		return true;
	}
	return false;
}

void updateScores() {
	int by, bx;
	getyx(boardwin, by, bx);
	wmove(capwin, 1, 0);
	wattron(capwin, COLOR_PAIR(Colors.PLAYER_ONE));
	version(pente) {
		waddch(capwin, 'y');
	}
	version (go) {
		waddch(capwin, 'b');
	}
	mvwprintw(capwin, 2, 0, "%d", g.getPlayer(0).caps);
	wattroff(capwin, COLOR_PAIR(Colors.PLAYER_ONE));
	wattron(capwin, COLOR_PAIR(Colors.PLAYER_TWO));
	wmove(capwin, 6, 0);
	version(pente) {
		waddch(capwin, 'r');
	}
	version(go) {
		waddch(capwin, 'w');
	}
	mvwprintw(capwin, 7, 0, "%d", g.getPlayer(1).caps);
	wattroff(capwin, COLOR_PAIR(Colors.PLAYER_TWO));
	wattron(capwin, COLOR_PAIR(g.getCurrentPlayer()+1));
	debug {
		mvwprintw(capwin, 9, 0, "%d", bx);
		mvwprintw(capwin, 10, 0, "%d", by);
		wmove(capwin, 11, 0);
		wprintw(capwin, "%d", g.getBoard().getContiguousPieces(0, 0).length);
		mvwprintw(capwin, 12, 0, "%d", g.getBoard().getBorderPieces(0, 0).length);
	}
	wrefresh(capwin);
	wrefresh(boardwin);
}

/**
 * Refreshes the display of the game board.
 */
void printBoard() {
	Board b = g.getBoard();
	for (int y = 0; y < b.getHeight(); y++) {
		wmove(boardwin, y, 0);
		for (int x = 0; x < b.getWidth(); x++) {
			int c = getPieceChar(b.getPiece(x, y));
			int colmod;
			switch (b.getPiece(x, y)) {
//				version (pente) case Piece.YELLOW:
//				version (go) case Piece.BLACK:
				case 1:
					colmod = COLOR_PAIR(Colors.PLAYER_ONE);
					break;
//				version (pente) case Piece.RED:
//				version (go) case Piece.BLACK:
				case 2:
					colmod = COLOR_PAIR(Colors.PLAYER_TWO);
					break;
				default:
					colmod = COLOR_PAIR(Colors.COLOR_DEFAULT);
					break;
			}
			waddch(boardwin, c | colmod);
		}
	}
}

void cleanup() {
	if (capwin != null) delwin(capwin);
	if (boardwin != null) delwin(boardwin);
	endwin();
}

void init_windows() {
	//newwin(rows, columns, starty, startx)
	boardwin = newwin(BOARD_HEIGHT, BOARD_WIDTH, 0, 0);
	leaveok(boardwin, false);
	capwin = newwin(BOARD_HEIGHT, SCORE_WIDTH, 0, BOARD_WIDTH + 1);
}

void setup_color() {
	start_color();
	version(pente) {
		init_pair(Colors.COLOR_DEFAULT, COLOR_WHITE, COLOR_BLACK);
		init_pair(Colors.PLAYER_ONE, COLOR_YELLOW, COLOR_BLACK);
		init_pair(Colors.PLAYER_TWO, COLOR_RED, COLOR_BLACK);
	}
	version (go) {
		init_pair(Colors.COLOR_DEFAULT, COLOR_YELLOW, COLOR_RED);
		init_pair(Colors.PLAYER_ONE, COLOR_BLACK, COLOR_RED);
		init_pair(Colors.PLAYER_TWO, COLOR_WHITE, COLOR_RED);
	}
}
