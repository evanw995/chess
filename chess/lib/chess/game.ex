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
		game #return new game object
	end

	#########################################################################
	# Start at target space, work backwards towards starting space of piece #
	# Check if there any pieces in the way (return false if so)             #
	# Call these functions recursively until targetSpace = startSpace       #
	#########################################################################

	### DETERMINE IF A MOVE IS LEGAL ###

	# Covers bishop case, can be used for pawns/queens/king
	def isLegalDiagonalMove(position, targetSpace, startSpace, color) do
		# placeholder
		false
	end

	# Covers rook case, can be used for pawns/queens/king
	def isLegalStraightMove(position, targetSpace, startSpace, color) do
		# placeholder
		false
	end

	def isLegalKnightMove(position, targetSpace, startSpace, color) do
		# placeholder
		false		
	end

	def isLegalKingMove(position, targetSpace, startSpace, color) do
		# placeholder
		false
	end

	def isLegalQueenMove(position, targetSpace, startSpace, color) do
		(isLegalStraightMove(position, targetSpace, startSpace, color) || isLegalDiagonalMove(position, targetSpace, startSpace, color))
	end

	### FUNCTIONS FOR NAVIGATING THE BOARD AND DETERMINING IF SPACES ARE AVAILABLE ###

	# Go up or down ranks. Direction 1 = add, -1 = subtract
	# Return string of new space
	def changeRank(space, direction) do
		fileString = String.at(space, 0)
		rankString = String.at(space, 1)
		rank = String.to_integer(rankString)
		cond do
			(rank == 1) && (direction == -1) -> # bad case
				space
			(rank == 8) && (direction == 1) -> # bad case
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
			fileIndex == 0 && direction == -1 -> #bad case
				space
			fileIndex == 7 && direction == 1 -> #bad case
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