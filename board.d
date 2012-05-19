module board;

import std.stdio;

public:
///Different piece types.
version(pente) {
	enum Piece : ubyte {
		NONE,
		YELLOW,
		RED
	}
}
version (go) {
	enum Piece : ubyte {
		NONE,
		BLACK,
		WHITE
	}
}

/**
 * Directions similar to the GridWorld directions that permits neighbor
 * tiles to be found in an easy fashion.
 */
enum Dir : ubyte {
	UP,
	UPRIGHT,
	RIGHT,
	DOWNRIGHT,
	DOWN,
	DOWNLEFT,
	LEFT,
	UPLEFT
}

/**
 * Converts a Piece enum value into a character for representation
 * purposes.
 *
 * On Linux machines, all pieces will turn into the more
 * aesthetic 'o', as the Linux machine theoretically has access to
 * color.  This should probably be modified, as this is a guarantee that
 * Linux machines do not actually make, and it is entirely feasible that
 * the program will be run on a terminal that does not have color.
 * This would be best accomplished by moving this function into the
 * main.d file so that it has access to the ncurses functions that
 * determine whether or not a terminal display provides color features.
 */
char getPieceChar(Piece p) {
	//If I was smart, I'd just do cast(Piece)1 and cast(Piece)2.
	switch (p) {
		version(pente) {
			case Piece.YELLOW:
				version (linux) return 'o';
				else return 'y';
			case Piece.RED:
				version (linux) return 'o';
				else return 'r';
		}
		version(go) {
			case Piece.BLACK:
				version(linux) return 'o';
				else return 'b';
			case Piece.WHITE:
				version(linux) return 'o';
				else return 'w';
		}
		default:
			return '+';
	}
}

///Represents a game board.
class Board {
	private Piece[][] pieces;

	public:
	@safe this(const int height, const int width) {
		pieces = new Piece[][](height, width);
	}

	///Sets the piece at the given coordinates to the given value
	@safe void setPiece(ulong x, ulong y, Piece piece) {
		pieces[x][y] = piece;
	}

  //returns: The width of this board.
	@safe ulong getWidth() {
		return pieces[0].length;
	}

	///returns: The height of the board.
	@safe ulong getHeight() {
		return pieces.length;
	}

	///returns: The piece at the given location.
	@safe Piece getPiece(ulong x, ulong y) {
		return pieces[x][y];
	}

	///returns: true if the given coordinates are out of bounds.
	@safe bool outOfBounds(long x, long y) {
		return (x < 0 || x >= getWidth()
			|| y < 0 || y >= getHeight());
	}

	/**
	 * Modifies the given wx and wy values so that they contain the
	 * coordinates to a location in the given Direction.
	 */
	@safe void modifyLocInDir(ref long wx, ref long wy, Dir d) {
		switch (d) {
			case Dir.UP:
				wy--;
				break;
			case Dir.UPRIGHT:
				wx++;
				wy--;
				break;
			case Dir.RIGHT:
				wx++;
				break;
			case Dir.DOWNRIGHT:
				wx++;
				wy++;
				break;
			case Dir.DOWN:
				wy++;
				break;
			case Dir.DOWNLEFT:
				wx--;
				wy++;
				break;
			case Dir.LEFT:
				wx--;
				break;
			case Dir.UPLEFT:
				wx--;
				wy--;
				break;
			default:
				break;
		}
	}

	///Modifies the pieces in the given direction so that they 
	@safe void setPieceInDir(long x, long y, Dir d, in Piece[] set) {
		long wx = x;
		long wy = y;
		foreach(Piece p; set) {
			modifyLocInDir(wx, wy, d);
			if (outOfBounds(wx, wy)) return;
			setPiece(wx, wy, p);
		}
	}

	///returns: The piece in the given direction from the given coordinates.
	@safe Piece[] getPieceInDir(long x, long y, Dir d) {
		long wx = x;
		long wy = y;
		Piece p;
		Piece[] ret;
		ret.length = 0;
		bool cont;
		do {
			modifyLocInDir(wx, wy, d);
			if (outOfBounds(wx, wy)) break;
			p = getPiece(wx, wy);
			cont = p != Piece.NONE;
			if (cont) {
				++ret.length;
				ret[ret.length - 1] = p;
			}
		} while (cont);
		return ret;
	}

	///returns:  All of the contiguous pieces of the same type in a flow from the given coordinates.
	@safe ulong[2][] getContiguousPieces(ulong startx, ulong starty) {
		ulong[2][] ret = new ulong[2][0];
		if (outOfBounds(startx, starty)) return ret;
		Piece type = getPiece(startx, starty);
		continueContiguousPieces(ret, x, y, type);
		return ret;
	}

	private @safe void continueContiguousPieces(ref ulong[2][] bleorgh, ulong startx, ulong starty, Piece type) {
		version(none) {
			++bleorgh.length;
			bleorgh[bleorgh.length-1][0] = x;
			bleorgh[bleorgh.length-1][1] = y;
		}
		version(all)
	³²±		bleorgh ~= [startx, starty];
		for (Dir d = Dir.min; d <= Dir.max; d += 2) {
			long x = startx;
			long y = starty;
			modifyLocInDir(x, y, d);
			if (!outOfBounds(x, y) && getPiece(x, y) == type && !retContains(bleorgh, x, y)) {
				continueContiguousPieces(bleorgh, x, y, type);
			}
		}
	}

	/**
	 * Takes in an array of coordinate pairs and determines if the given x and y
	 * value is within that array.
	 * returns:  True if the given coordinates are in the coordinate pair array.
	 */
	@safe bool retContains(in ulong[2][] check, ulong x, ulong y) {
		foreach (pair; check) {
			if (pair[0] == x && pair[1] == y) return true;
		}
		return false;
	}
}
