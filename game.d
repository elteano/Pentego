module game;

//This is necessary because main.d is too lazy to import board.d
public import board;
import std.stdio;

///Data structure containing information for players
struct Player {
	///Color of pieces/which player
	Piece color;
	///Number of pieces/pairs this player has captured
	ubyte caps;
	version(pente)
		///Remembers if this player has five in a row (and so should win pente)
		bool has_pente;
}

/**
 * Class representing any given game.  Theoretically, using multiple
 * instances of this class would allow multiple games to be played
 * at any given point in time.
 */
public class Game {
	private:
	///Board used for the game
	Board board;
	///Whose turn is it?
	ubyte curPlayer;
	///Array containing all the players
	public Player[2] p;

	public:
	this(uint width, uint height) {
		board = new Board(width,height);
		version(pente) {
			p[0].color = Piece.YELLOW;
			p[1].color = Piece.RED;
		}
		version (go) {
			p[0].color = Piece.BLACK;
			p[1].color = Piece.WHITE;
		}
		curPlayer = 0;
	}

	///returns: The indicated player.
	Player getPlayer(int num) {
		return p[num];
	}

	///returns: The playing board.
	Board getBoard() {
		return board;
	}

	///returns: The number of the currently playing player.
	uint getCurrentPlayer() {
		return curPlayer;
	}

	///Causes the current player to play a piece at the specified location.
	void playPiece(uint x, uint y) {
		if (board.getPiece(x, y) != Piece.NONE)
			return;
		version(go) {
			//Proceed to check for suicide play
			//Read:  PAIN
		}
		board.setPiece(x, y, p[curPlayer].color);
		version(pente) {
		Piece[][8] adjacentPieces;
		//foreach (Dir d, ref line; adjacentPieces) {
			for (Dir d = Dir.min; d < 8; d++) {
				++adjacentPieces[d].length;
				adjacentPieces[d] = board.getPieceInDir(x, y, d);
			}
			uint[8] counts;
			foreach (ubyte dir, Piece[] line; adjacentPieces) {
				if (line.length > 2 && line[0] == line[1]
					&& line[1] != p[curPlayer].color
					&& line[2] == p[curPlayer].color) {
						p[curPlayer].caps++;
						board.setPieceInDir(x, y, cast(Dir) dir,
							[Piece.NONE, Piece.NONE]);
						continue;
				}
				for (; counts[dir] < line.length && line[counts[dir]] == p[curPlayer].color; counts[dir]++) {}
			}
			uint[4] subCounts;
			foreach (int i, ref b; subCounts) {
				b = counts[i] + counts[i+4] + 1;
				if (b >= 5)
					p[curPlayer].has_pente = true;
			}
		}
		nextPlayer();
	}

	/**
	 * Determines which player should win.
	 * returns:   -1 if there is no victor,
	 *					< -1 if there is a tie,
	 *					>= 0 to indicate the victor.
	 */
	public int getVictor() {
		int ret = -1;
		version(pente) {
			foreach (int c, Player player; p) {
				if (player.has_pente || player.caps > 4)
					ret += c + 1;
			}
		}
		version(go){
			writef("Oops, getVictor not yet implemented for Go!");
		}
		if (ret >= p.length)
			ret = -2;
		return ret;
	}

	///Moves on to the next player's turn
	void nextPlayer() {
		curPlayer ^= 1;
	}
}
