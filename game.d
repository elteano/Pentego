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
	version(go)
		bool lastSkipped = false;

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
		//Don't allow pieces to be placed over pieces
		if (board.getPiece(x, y) != Piece.NONE)
			return;
		board.setPiece(x, y, p[curPlayer].color);
		version(go) {
			//Guilty until proven innocent here.
			bool suicidePlay = true;
			//Search through the borders to see if one makes this play valid.
			foreach (pair; board.getBorderPieces(x, y)) {
				if (board.getPiece(pair[0], pair[1]) == Piece.NONE) {
					suicidePlay = false;	//INNOCENT!
					break;	//No point searching any more
				}
			}
			if (suicidePlay) {
				//Reset the piece and make them play somewhere else.
				board.setPiece(x, y, Piece.NONE);
				return;
			}
			//See if opponent pieces have been surrounded
			for (Dir d = Dir.min; d <= Dir.max; d += 2) {
				long mx = x;
				long my = y;
				board.modifyLocInDir(mx, my, d);
				if (!board.outOfBounds(mx, my) && board.getPiece(mx, my) != p[curPlayer].color && board.getPiece(mx, my) != Piece.NONE) {
					//Surround check
					bool allSame = true;
					ulong[2][] bounds = board.getBorderPieces(mx, my);
					foreach (pair; bounds) {
						if (board.getPiece(pair[0], pair[1]) != p[curPlayer].color) {
							allSame = false;
							break;
						}
					}
					if (allSame) {
						//Increase current player's cap count, remove pieces
						ulong[2][] field = board.getContiguousPieces(mx, my);
						p[curPlayer].caps += field.length;
						foreach (pair; field) {
							board.setPiece(pair[0], pair[1], Piece.NONE);
						}
					}
				}
			}
		}
		version(pente) {
		Piece[][8] adjacentPieces;	//array of size 8 of arrays of indefinite lengths of pieces
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
			bool victorExists = false;
			foreach (int c, Player player; p) {
				if (player.has_pente || player.caps > 4) {
					//Set result to tie if it is proper
					if (victorExists)
						ret = -2;
					else {	//Set the victor to the victor (incremented for human readability)
						ret += c + 1;
						victorExists = true;
					}
				}
			}
		}
		version(go){
			ulong[2][] p0field = new ulong[2][0];
			ulong[2][] p1field = new ulong[2][0];
			for (int x = 0; x < board.getWidth(); x++) {
				for (int y = 0; y < board.getHeight(); y++) {
					//Only count empty fields.
					if (board.getPiece(x, y) != Piece.NONE)
						continue;
					ulong[2][] bounds = board.getBorderPieces(x, y);
					//Make sure that all border pieces are of the same type
					Piece first = board.getPiece(bounds[0][0], bounds[0][1]);
					bool same = true;
					foreach (pair; bounds) {
						if (board.getPiece(pair[0], pair[1]) != first) {
							same = false;
							break;
						}
					}
					//Give credit where it is due
					if (same) {
						if (same == Piece.BLACK && !board.retContains(p0field, x, y)) {
							p0field ~= board.getContiguousPieces(x, y);
							continue;
						}
						if (same == Piece.WHITE && !board.retContains(p1field, x, y)) {
							p1field ~= board.getContiguousPieces(x, y);
							continue;
						}
					}
				}
			}
			long p0count = p0field.length - p[1].caps;
			long p1count = p1field.length - p[0].caps;
			if (p0count > p1count)	//p0 has more surrounded tiles
				ret = 0;
			else if (p1count > p0count)	//p1 has more surrounded tiles
				ret = 1;
			else	//Same number of surrounded tiles
				ret = -3;
			/*
			 * Algorithm used above
			 * ^^^^^^^^^^^^^^^^^^^^
			 *
			 * Foreach space
			 * if empty
			 * if all borders are the same
			 * if not already contained in counted space
			 * total contiguous spaces
			 *
			 * Determine which player has more encapsulated spaces
			 */
		}
		return ret;
	}

	version(go) {
		/**
		 * Skips the current player's turn.  This is different from merely calling nextPlayer, as
		 * if this function is called twice in sequence, it will return a value of 1 signalling
		 * that the game should end.
		 */
		int pass() {
			//If the last player skipped, then return 1 to signal that the game should end.
			if (lastSkipped)
				return 1;
			//Move on to the next player; this method sets lastSkipped to false, but we already know it's false.
			nextPlayer();
			lastSkipped = true;
			return 0;
		}
	}

	///Moves on to the next player's turn
	void nextPlayer() {
		//Set lastSkipped to false so that the next player may pass as usual.
		version(go)
			lastSkipped = false;
		version(none) {
			//I was feeling witty.
			curPlayer ^= 1;
		}
		version(all) {
			//Cycle around to the next player.
			curPlayer = (curPlayer+1)%p.length;
		}
	}
}
