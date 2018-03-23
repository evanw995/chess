defmodule Memory.Game do
  def newGame() do
    %{
      position: startPosition(),
      gameOver: false,
      turn: 'w',
      whiteKingsideCastle: true,
      blackKingsideCastle: true,
      whiteQueensideCastle: true,
      blackQueensideCastle: true,
			whiteKingSpace: 'e1', # Makes it easier to validate checks/checkmate
			blackKingSpace: 'e8', # ^^^
      inCheck: false,
      enPassantSquare: '' # If a pawn moves two spaces, set this to the space it skips over. 
													# Every other move will reset this back to empty string
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
			(move.newLocation == move.oldLocation) -> # That's not a move!
				game
			(piece == 'P') -> # Pawn move
				if isLegalPawnMove(game.position, move.newLocation, move.oldLocation, color, game.enPassantSquare) do
					pieceMovedGameState = performMove(game, move)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game 
				end
			(piece == 'R') -> # Rook move
				if isLegalStraightMove(game.position, move.newLocation, move.oldLocation, color) do
					pieceMovedGameState = performMove(game, move)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game
				end
			(piece == 'B') -> # Bishop move
				if isLegalDiagonalMove(game.position, move.newLocation, move.oldLocation, color) do
					pieceMovedGameState = performMove(game, move)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game
				end
			(piece == 'N') -> # Knight move
				if isLegalKnightMove(game.position, move.newLocation, move.oldLocation, color) do
					pieceMovedGameState = performMove(game, move)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game
				end
			(piece == 'Q') -> # Queen move
				if isLegalQueenMove(game.position, move.newLocation, move.oldLocation, color) do
					pieceMovedGameState = performMove(game, move)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game
				end
			(piece == 'K') -> # King move
				if isLegalKingMove(game, move.newLocation, move.oldLocation, color) do
					pieceMovedGameState = performMove(game, move)
					newGameState = checkGameState(pieceMovedGameState) # TODO: Check for checks on both sides, as king move could open a check on opponent
					newGameState
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
	# - adding piece to target square, removing piece from source square
	def performMove(game, move) do
		game # return new game object
	end

	###################################################################################
	# Get list of geometrically viable moves                                          #
	# Check if target space is in that list of viable moves                           #
	# Check to make sure there are no pieces in between start space and target        #
	###################################################################################

	### DETERMINE IF A MOVE IS LEGAL ###

	# Covers bishop case, can be used for pawns/queens/king
	def isLegalDiagonalMove(position, targetSpace, startSpace, color) do
		diagonal = findCorrectDiagonal(startSpace, targetSpace)
		size = Enum.count(diagonal)
		cond do
			size == 0 ->
				false # No diagonal contains target and start space, illegal move
			Map.has_key?(position, targetSpace) -> # contains a piece on target spot
				piece = position[:targetSpace]
				pieceColor = String.at(piece, 0)
				index = Enum.find_index(diagonal, targetSpace) - 1
				squares = Enum.slice(diagonal, 1..index)
				if (pieceColor == enemyColor(color) && containsNoPieces(squares, position)) do # Enemy piece & nothing in the way
					true
				else # Friendly piece, illegal move
					false
				end
			true -> # Target space is empty, check for pieces in the way
				index = Enum.find_index(diagonal, targetSpace) - 1
				squares = Enum.slice(diagonal, 1..index)
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
			Map.has_key?(position, targetSpace) -> # contains a piece on target spot
				piece = position[:targetSpace]
				pieceColor = String.at(piece, 0)
				index = Enum.find_index(straight, targetSpace) - 1
				squares = Enum.slice(straight, 1..index)
				if (pieceColor == enemyColor(color) && containsNoPieces(squares, position)) do # Enemy piece & nothing in the way
					true
				else # Friendly piece, illegal move
					false
				end
			true -> # Target space is empty, check for pieces in the way
				index = Enum.find_index(straight, targetSpace) - 1
				squares = Enum.slice(straight, 1..index)
				containsNoPieces(squares, position) # If no pieces are in between start space and target space, move is valid (provided not in check)
		end
	end

	# Return true if the given move is a legal knight move in the position
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

	# Return true if given move is a legal queen move in position
	def isLegalQueenMove(position, targetSpace, startSpace, color) do
		(isLegalStraightMove(position, targetSpace, startSpace, color) || isLegalDiagonalMove(position, targetSpace, startSpace, color))
	end

	# Will need to run a helper function to make sure king isn't moving into check
	# Will also need to check for castling case-- hard code spaces?
	def isLegalKingMove(game, targetSpace, startSpace, color) do
		files = 'abcdefgh'
		position = game.position
		# king
		startFileString = String.at(startSpace, 0)
		startFileIndex = elem(:binary.match(files, startFileString), 0)
		startRank = String.to_integer(String.at(startSpace, 1))
		# target
		targetFileString = String.at(targetSpace, 0)
		targetFileIndex = elem(:binary.match(files, targetFileString), 0)
		targetRank = String.to_integer(String.at(targetSpace, 1))
		cond do
			startSpace == 'e1' && targetSpace == 'g1' ->
				if color == 'w' && game.whiteKingsideCastle do
					true
				else
				false
				end
			startSpace == 'e1' && targetSpace == 'c1' ->
				if color == 'w' && game.whiteQueensideCastle do
					true
				else
				false
				end
			startSpace == 'e8' && targetSpace == 'g8' ->
				if color == 'b' && game.blackKingsideCastle do
					true
				else
				false
				end
			startSpace == 'e8' && targetSpace == 'c8' ->
				if color == 'b' && game.blackQueensideCastle do
					true
				else
				false
				end
			abs(startFileIndex - targetFileIndex) < 2 && abs(startRank - targetRank) < 2 -> # Move must be within one space in any direction
				if spaceAvailable(position, targetSpace, color) do
					true
				else
					(String.at(position[:targetSpace], 0) != color)
				end
			true ->
				false
		end
	end

	# Return true if given move is a legal pawn move in position
	def isLegalPawnMove(position, targetSpace, startSpace, color, enPassantSquare) do
		moves = listLegalPawnMoves(position, color, startSpace, enPassantSquare)
		Enum.member?(moves, targetSpace)
	end

	# Lists possible spaces a knight can move to (does not account for whether or not the spaces are occupied)
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

	# TODO-- change this to fit format of others? (Use isLegalDiagonal/StraightMove()?)
	def listLegalPawnMoves(position, color, startSpace, enPassantSquare) do
		startRank = String.to_integer(String.at(startSpace, 1))
		startFile = String.at(startSpace, 0)
		moves = []

		cond do
			color == 'w' -> # white pieces
				forwardSpace = changeRank(startSpace, 1)
				leftCapture = changeRank(changeFile(startSpace, -1), 1)
				leftCapture = changeRank(changeFile(startSpace, 1), 1)
				doubleSpace = changeRank(startSpace, 2)
			true -> # black pieces
				forwardSpace = changeRank(startSpace, -1)
				leftCapture = changeRank(changeFile(startSpace, -1), -1)
				leftCapture = changeRank(changeFile(startSpace, 1), -1)
				doubleSpace = changeRank(startSpace, -2)
		end
		# Check forward moves
		if spaceAvailable(position, forwardSpace, color) do
				if spaceAvailable(position, doubleSpace, color) do
					moves = Enum.concat([moves, [doubleSpace]])
				end
			moves = Enum.concat([moves, [forwardSpace]])
		end
		# Check captures
		cond do
			position[:leftCapture] != nil ->
				if String.at(position[:leftCapture], 0) == enemyColor(color) do
					moves = Enum.concat([moves, [leftCapture]])
				end
			enPassantSquare == leftCapture ->
				moves = Enum.concat([moves, [leftCapture]])	
		end
		cond do
			position[:rightCapture] != nil ->
				if String.at(position[:rightCapture], 0) == enemyColor(color) do
					moves = Enum.concat([moves, [rightCapture]])
				end
			enPassantSquare == rightCapture ->
				moves = Enum.concat([moves, [rightCapture]])	
		end
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

	######################
	# GAME STATE HELPERS #
	######################
	
	# Return full game state 
	def checkGameState(game) do
		kingSpace = if game.turn == 'w' do
			game.whiteKingSpace
		else
			game.blackKingSpace
		end
		newState = Map.put(game, :isCheck, isCheck(game.position, game.turn, kingSpace))
		gameOver = (isCheckMate(game.position, game.turn, kingSpace) || isStaleMate(game.position, game.turn, kingSpace))
		newState1 = Map.put(newState, :gameOver, gameOver)
		newState1
	end

	# Tough function: Determine whether king is in check
	# - Check all opponent pieces and see if they could move to the king's space
	# Color is whose turn it is (white moving, see if white king is in check)
	def isCheck(position, color, kingSpace) do
		# placeholder
		enemyColor = enemyColor(color)
		pieces = Map.to_list(position)
		king = '#{color}K'
		checks = Enum.map(pieces, fn({k, v}) ->
			if String.at(v, 0) == enemyColor do
				piece = String.at(v, 1)
				cond do
					piece == 'P' ->
						isLegalPawnMove(position, kingSpace, k, color, '')
					piece == 'R' ->
						isLegalStraightMove(position, kingSpace, k, color)
					piece == 'N' ->
						isLegalKnightMove(position, kingSpace, k, color)
					piece == 'B' ->
						isLegalDiagonalMove(position, kingSpace, k, color)
					piece == 'Q' ->
						isLegalQueenMove(position, kingSpace, k color)
				end
			end 
		end)
		Enum.member?(checks, true)
	end

	# Determines if the position is checkmate for given color
	# If king is in check, validate whether king is in check after all possible moves for given color 
	def isCheckMate(position, color, kingSpace) do
		# placeholder
		false
	end

	# Opposite of checkmate function-- king is not in check, but all legal moves would place him in check
	def isStaleMate(position, color, kingSpace) do
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
        'a1': 'wR',
        'b1': 'wN',
        'c1': 'wB',
        'd1': 'wQ',
        'e1': 'wK',
        'f1': 'wB',
        'g1': 'wN',
        'h1': 'wR',
        'a2': 'wP',
        'b2': 'wP',
        'c2': 'wP',
        'd2': 'wP',
        'e2': 'wP',
        'f2': 'wP',
        'g2': 'wP',
        'h2': 'wP',
        'a8': 'bR',
        'b8': 'bN',
        'c8': 'bB',
        'd8': 'bQ',
        'e8': 'bK',
        'f8': 'bB',
        'g8': 'bN',
        'h8': 'bR',
        'a7': 'bP',
        'b7': 'bP',
        'c7': 'bP',
        'd7': 'bP',
        'e7': 'bP',
        'f7': 'bP',
        'g7': 'bP',
        'h7': 'bP'
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