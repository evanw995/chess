defmodule Memory.Game do
  def newGame() do
    %{
      position: startPosition(),
      gameOver: false,
      turn: 'w',
      whiteCanCastle: true,
      blackCanCastle: true,
      inCheck: false,
      enPassantSquare: ''
    }
  end

	## Game object logic: 
	## gameOver = true, inCheck = false would signify a draw
	## gameOver = true, inCheck = true would signify checkmate (use turn to determine who is winner/loser)

  def client_view(game) do
    %{
      position: game.position, # Required to play game
      gameOver: game.gameOver, # View should change when game is over
      turn: game.turn, # Client should see whose turn it is
      inCheck: game.inCheck, # Could be useful for notification for client
    }
  end

	# Move handling function from channel input
  def move(game, move) do
		color = String.at(move.piece, 0)
		piece = String.at(move.piece, 1)
    cond do
    	(color != game.turn) -> # Cannot move that color
				game
			(move.piece != game.position[:move.source]) -> # That piece isn't on that square, how did you even call this?
				game
			(piece == 'P') -> # Pawn move
				# If getLegalPawnMoves contains move
				# perform move and return new game object 
			(piece == 'R') -> # Rook move
				if isLegalStraightMove(game.position, move.newLocation, move.oldLocation, color) do
					# Perform move and return new game object
				else
					game
				end
			(piece == 'B') -> # Bishop move
				if isLegalDiagonalMove(game.position, move.newLocation, move.oldLocation, color) do
					# Perform move and return new game object
				else
					game
				end
			(piece == 'N') -> # Knight move
				if isLegalKnightMove(game.position, move.newLocation, move.oldLocation, color) do
					# Perform move and return new game object
				else
					game
				end
			(piece == 'Q') -> # Queen move
				if isLegalQueenMove(game.position, move.newLocation, move.oldLocation, color) do
					# Perform move and return new game object
				else
					game
				end
			(piece == 'K') -> # King move
				if isLegalKingMove(game.position, move.newLocation, move.oldLocation, color) do
					# Perform move and return new game object
				else
					game
				end
		end
  end

	## Helper for move function. Must handle:
	# - castling
	# - en passant
	# - captures
	# - piece promotion (auto-queen or not?)
	def performMove(game, move) do
		game # return new game object
	end

	#########################################################################
	# Start at target space, work backwards towards starting space of piece #
	# Check if there any pieces in the way (return false if so)             #
	# Call these functions recursively until targetSpace = startSpace       #
	#########################################################################

	### DETERMINE IF A MOVE IS LEGAL ###

	# Covers bishop case, can be used for pawns/queens/king
	def isLegalDiagonalMove(position, targetSpace, startSpace, color) do
		diagonal = findCorrectDiagonal(startSpace, targetSpace)
		size = Enum.count(diagonal)
		cond do
			size == 0 ->
				false # No diagonal contains target and start space, illegal move
			true ->
				index = Enum.find_index(diagonal, targetSpace) - 1
				Enum.slice(diagonal, 1..index)
				containsNoPieces(squares, position) # If no pieces are in between start space and target space, move is valid (provided not in check)
		end
	end

	# Covers rook case, can be used for pawns/queens/king
	def isLegalStraightMove(position, targetSpace, startSpace, color) do
		straight = findCorrectStraight(startSpace, targetSpace)
		size = Enum.count(straight)
		cond do
			size == 0 ->
				false # No straight contains target and start space, illegal move
			true ->
				index = Enum.find_index(straight, targetSpace) - 1
				Enum.slice(straight, 1..index)
				containsNoPieces(squares, position) # If no pieces are in between start space and target space, move is valid (provided not in check)
		end
	end

	# Return true if given enum of squares contains no pieces in game position
	def containsNoPieces(squares, position) do
		size = Enum.count(squares)
		cond do
			size == 0 -> # No more items to check, return true
				true
			Map.has_key?(position, space) -> # Space contained in position object = occupied by piece
				false
			true ->
				containsNoPieces(Enum.slice(squares, 1..size-1), position) # Recurse
		end
	end

	def isLegalKnightMove(position, targetSpace, startSpace, color) do
		listKnightMoves = listAllKnightMoves(startSpace)
		cond do
			!Enum.member?(listKnightMoves, targetSpace) -> # is not a valid move from current position
				false
			Map.has_key?(position, targetSpace) -> # contains a piece on target spot
				piece = position[:targetSpace]
				pieceColor = String.at(piece, 0)
				if (pieceColor == enemyColor(color)) do # Enemy piece
					true
				else # Friendly piece, illegal move
					false
				end
			true -> # Valid knight move, no piece on target space
				true
		end		
	end

	# Will need to run a helper function to make sure king isn't moving into check
	# Will also need to check for castling case-- hard code spaces?
	def isLegalKingMove(position, targetSpace, startSpace, color) do
		# placeholder
		false
	end

	def isLegalQueenMove(position, targetSpace, startSpace, color) do
		(isLegalStraightMove(position, targetSpace, startSpace, color) || isLegalDiagonalMove(position, targetSpace, startSpace, color))
	end

	def listAllKnightMoves(space) do
		space1 = [changeFile(changeRank(space, 1) 2)]
		space2 = [changeFile(changeRank(space, -1) 2)]
		space3 = [changeFile(changeRank(space, 1) -2)]
		space4 = [changeFile(changeRank(space, -1) -2)]
		space5 = [changeFile(changeRank(space, 2) 1)]
		space6 = [changeFile(changeRank(space, 2) -1)]
		space7 = [changeFile(changeRank(space, -2) 1)]
		space8 = [changeFile(changeRank(space, -2) -1)]
		allSpaces = Enum.concat([space1, space2, space3, space4, space5, space6, space7, space8])
		dedupSpaces = Enum.dedup(allSpaces)
		dedupSpaces
	end

	##################################################################################
	### FUNCTIONS FOR NAVIGATING THE BOARD AND DETERMINING IF SPACES ARE AVAILABLE ###
	##################################################################################

	# Return an enum of spaces on the diagonal from the start space that contains the target space
	# Return empty if no diagonal exists
	def findCorrectDiagonal(startSpace, targetSpace) do
		diagonal1 = getSquares(startSpace, -1, -1, []) # down-left
		diagonal2 = getSquares(startSpace, -1, 1, []) # up-left
		diagonal3 = getSquares(startSpace, 1, -1, []) # down-right
		diagonal4 = getSquares(startSpace, 1, 1, []) # up-right
		cond do
			Enum.member?(diagonal1, targetSpace) ->
				diagonal1
			Enum.member?(diagonal2, targetSpace) ->
				diagonal2
			Enum.member?(diagonal3, targetSpace) ->
				diagonal3
			Enum.member?(diagonal4, targetSpace) ->
				diagonal4
			true ->
				[]
		end
	end

	# Return an enum of spaces on the straight from the start space that contains the target space
	# Return empty if no straight exists
	def findCorrectStraight(startSpace, targetSpace) do
		straight1 = getSquares(startSpace, 0, 1, []) # up
		straight2 = getSquares(startSpace, 0, -1, []) # down
		straight3 = getSquares(startSpace, 1, 0, []) # right
		straight4 = getSquares(startSpace, -1, 0, []) # left
		cond do
			Enum.member?(straight1, targetSpace) ->
				straight1
			Enum.member?(straight2, targetSpace) ->
				straight2
			Enum.member?(straight3, targetSpace) ->
				straight3
			Enum.member?(straight4, targetSpace) ->
				straight4
			true ->
				[]
		end
	end

	# Returns the enum of squares in given direction from space
	def getSquares(space, fileDirection, rankDirection, squares) do
		files = 'abcdefgh'
		fileString = String.at(space, 0)
		fileIndex = elem(:binary.match(files, fileString), 0)
		rank = String.to_integer(String.at(space, 1))
		newSquares = Enum.concat(squares, [space])
		if (fileIndex + fileDirection > 7 || rank + rankDirection > 8 ||
				fileIndex + fileDirection < 0 || rank + rankDirection < 1) do
			newSquares
		else
			getSquares(getAdjacentSpace(space, fileDirection, rankDirection), fileDirection, rankDirection, newSquares)
		end
	end

	# Get space diagonal from given space
	def getAdjacentSpace(space, fileDirection, rankDirection) do
		spaceWithFileChange = changeFile(space, fileDirection)
		newSpace = changeRank(spaceWithFileChange, rankDirection)
		newSpace
	end

	# Go up or down ranks. Direction 1 = add, -1 = subtract
	# Return string of new space
	def changeRank(space, direction) do
		fileString = String.at(space, 0)
		rankString = String.at(space, 1)
		rank = String.to_integer(rankString)
		cond do
			(rank + direction < 1) || (rank + direction > 8) -> # bad case
				space
			true ->
				newRank = rank + direction
				newRankString = Integer.to_string(newRank)
				newSpace = fileString + newRankString
				newSpace
		end
	end

	# Changes files. Direction 1 = towards H file, -1 = towards A file
	# Return string of new space
	def changeFile(space, direction) do
		files = 'abcdefgh'
		fileString = String.at(space, 0)
		fileIndexMatch = :binary.match(files, fileString)
		fileIndex = elem(fileIndexMatch, 0)
		rankString = String.at(space, 1)
		cond do
			(fileIndex + direction < 0) || (fileIndex + direction > 7) -> # bad case
				space
			true ->
				newFileIndex = fileIndex + direction
				newFile = String.at(files, newFileIndex)
				newFileIndexString = Integer.to_string(newFile)
				newSpaceString = newFileIndexString + rankString
				newSpaceString
		end
	end
	
	# Return true if the space is empty
	def spaceAvailable(position, space, color) do
		if Map.has_key?(position, space) do # Is this space in the position object
			false
		else # Must be empty
			true
		end
	end

	def getLegalPawnMoves(position, color, startSpace) do
		getLegalPawnMoves(position, color, startSpace, [])
	end

	# TODO-- change this to fit format of others? (Use isLegalDiagonal/StraightMove()?)
	def getLegalPawnMoves(position, color, startSpace, moves) do
		files = 'abcdefgh'
		ranks = '12345678'
		# Get forward moves
		cond do
			(color == 'w')) ->
				# if spaceAvailable(position, String.at(startSpace, 0) + () )
		  # Pawns in starting position
			((String.at(start, 1) == '2') && (color == 'w')) ->
			((String.at(start, 1) == '7') && (color == 'b')) ->
			# Else
		end
		# Get possible attack moves
		cond do
			color == 'w' ->
			color == 'b' ->
		end
		# return
		moves
	end	

	########################################################################
	# May need functions like these to figure out if king is in check/mate #
	########################################################################

	# def getLegalBishopMoves(position, color) do
		
	# end
	
	# def getLegalKnightMoves(position, color) do
		
	# end

	# def getLegalRookMoves(position, color) do
		
	# end

	# def getLegalQueenMoves(position, color) do
		
	# end

	# def getLegalKingMoves(position, color) do
		
	# end

	# Tough function: Determine whether king is in check
	# Possible methods:
	# - Check all opponent pieces and see if they could move to the king's space
	def isCheck(game) do
		# placeholder
		false
	end

	# Helper function
	# Return opponents color
	def enemyColor(color) do
		if color == 'w' do
			'b'
		else
			'w'
		end
	end

  ####################
	### INITIALIZERS ###
	####################

	# hard coded start position as a position object, easily usable by chessboard.js library
	# when moving pieces from squares, be sure to delete the key from the map 
  def startPosition() do
    %{
        a1: 'wR',
        b1: 'wN',
        c1: 'wB',
        d1: 'wQ',
        e1: 'wK',
        f1: 'wB',
        g1: 'wN',
        h1: 'wR',
        a2: 'wP',
        b2: 'wP',
        c2: 'wP',
        d2: 'wP',
        e2: 'wP',
        f2: 'wP',
        g2: 'wP',
        h2: 'wP',
        a8: 'bR',
        b8: 'bN',
        c8: 'bB',
        d8: 'bQ',
        e8: 'bK',
        f8: 'bB',
        g8: 'bN',
        h8: 'bR',
        a7: 'bP',
        b7: 'bP',
        c7: 'bP',
        d7: 'bP',
        e7: 'bP',
        f7: 'bP',
        g7: 'bP',
        h7: 'bP'
    }
  end

	## Could use FEN string to represent game object (may look cleaner in this function)
	## but code to check and enfore rules will be more complicated.

  # def startPosition() do
  #   %{
  #       'RNBQKBNR/PPPPPPPP/8/8/8/8/PPPPPPPP/RNBQKBNR'
  #   }
  # end

end