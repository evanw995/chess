defmodule Chess.Game do
  def newGame() do
    %{
      position: startPosition(),
      gameOver: false,
      turn: "w",
      whiteKingsideCastle: true,
      blackKingsideCastle: true,
      whiteQueensideCastle: true,
      blackQueensideCastle: true,
	  whiteKingSpace: "e1", # Makes it easier to validate checks/checkmate
	  blackKingSpace: "e8", # ^^^
      inCheck: false,
      enPassantSquare: "" # If a pawn moves two spaces, set this to the space it skips over. 
													# Every other move will reset this back to empty string
    }
  end

  def client_view(game) do
    %{
      position: game.position, # Required to play game
      gameOver: game.gameOver, # View should change when game is over
      turn: game.turn, # Client should see whose turn it is
      inCheck: game.inCheck, # Could be useful for notification for client
    }
  end

	# Move handling function from channel input
  def move(game, oldLocation, newLocation, piece) do
		color = String.at(piece, 0)
		piece = String.at(piece, 1)
    cond do
    	(color != game.turn) -> # Cannot move that color
				game
			(piece != game.position[String.to_atom(oldLocation)]) -> # That piece isn"t on that square, how did you even call this?
				game
			(newLocation == oldLocation) -> # That"s not a move!
				game
			(piece == "P") -> # Pawn move
				if isLegalPawnMove(game.position, newLocation, oldLocation, color, game.enPassantSquare) do
					pieceMovedGameState = pawnMove(game, oldLocation, newLocation)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game 
				end
			(piece == "R") -> # Rook move
				if isLegalStraightMove(game.position, newLocation, oldLocation, color) do
					pieceMovedGameState = rookMove(game, oldLocation, newLocation)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game
				end
			(piece == "B") -> # Bishop move
				if isLegalDiagonalMove(game.position, newLocation, oldLocation, color) do
					pieceMovedGameState = performMove(game, oldLocation, newLocation)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game
				end
			(piece == "N") -> # Knight move
				if isLegalKnightMove(game.position, newLocation, oldLocation, color) do
					pieceMovedGameState = performMove(game, oldLocation, newLocation)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game
				end
			(piece == "Q") -> # Queen move
				if isLegalQueenMove(game.position, newLocation, oldLocation, color) do
					pieceMovedGameState = performMove(game, oldLocation, newLocation)
					newGameState = checkGameState(pieceMovedGameState)
					newGameState
				else
					game
				end
			(piece == "K") -> # King move
				if isLegalKingMove(game, newLocation, oldLocation, color, game.inCheck) do
					pieceMovedGameState = kingMove(game, oldLocation, newLocation)
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
	def performMove(game, oldLocation, newLocation) do
		position = game.position

		oldLocationRank = String.to_integer(String.at(oldLocation, 1))
		newLocationRank = String.to_integer(String.at(newLocation, 1))

		# keys to access map
		oldLocationAtom = String.to_atom(oldLocation)
		newLocationAtom = String.to_atom(newLocation)
		piece = position[oldLocation]
		removePiece = Map.delete(position, oldLocationAtom)
		newPosition = Map.put(removePiece, newLocationAtom, piece)
		newGameState = Map.put(game, :position, newPosition)

		newGameState1 = cond do 
			piece == "P" && abs(oldLocationRank - newLocationRank) == 2 -> # Pawn moved two spaces, enable en passant square
				fileString = String.at(oldLocation, 0)
				middleSquare = (oldLocationRank + newLocationRank) / 2
				middleSquareString = Integer.to_string(middleSquare)
				Map.put(newGameState, :enPassantSquare, "#{fileString}#{middleSquareString}")
			true ->
				Map.put(newGameState, :enPassantSquare, "")
		end
		newGameState1
	end

	# Must nullify that side castling
	def rookMove(game, oldLocation, newLocation) do
		castleGameState = cond do
			oldLocation == "a1" && game.whiteQueensideCastle ->
				Map.put(game, :whiteQueensideCastle, false)
			oldLocation == "h1" && game.whiteKingsideCastle ->
				Map.put(game, :whiteKingsideCastle, false)
			oldLocation == "a8" && game.blackQueensideCastle ->
				Map.put(game, :blackQueensideCastle, false)
			oldLocation == "h8" && game.blackKingsideCastle ->
				Map.put(game, :blackKingsideCastle, false)
			true ->
				game
		end
		performMove(castleGameState, oldLocation, newLocation)
	end

	# Must handle castling and set castling rights
	def kingMove(game, oldLocation, newLocation) do
		cond do
			oldLocation == "e1" && game.whiteQueensideCastle && newLocation == "c1" ->
				newState = Map.put(game, :whiteQueensideCastle, false)
				newState1 = Map.put(newState, :whiteKingsideCastle, false)
				moveKing = performMove(newState1, oldLocation, newLocation)
				moveKingState = Map.put(moveKing, :whiteKingSpace, "c1")
				performMove(moveKingState, "a1", "d1")
			oldLocation == "e1" && game.whiteKingsideCastle && newLocation == "g1" ->
				newState = Map.put(game, :whiteQueensideCastle, false)
				newState1 = Map.put(newState, :whiteKingsideCastle, false)
				moveKing = performMove(newState1, oldLocation, newLocation)
				moveKingState = Map.put(moveKing, :whiteKingSpace, "g1")
				performMove(moveKingState, "h1", "f1")
			oldLocation == "e8" && game.blackQueensideCastle && newLocation == "c8" ->
				newState = Map.put(game, :blackQueensideCastle, false)
				newState1 = Map.put(newState, :blackKingsideCastle, false)
				moveKing = performMove(newState1, oldLocation, newLocation)
				moveKingState = Map.put(moveKing, :whiteKingSpace, "c8")
				performMove(moveKingState, "a8", "d8")
			oldLocation == "e8" && game.blackKingsideCastle && newLocation == "g8" ->
				newState = Map.put(game, :blackQueensideCastle, false)
				newState1 = Map.put(newState, :blackKingsideCastle, false)
				moveKing = performMove(newState1, oldLocation, newLocation)
				moveKingState = Map.put(moveKing, :whiteKingSpace, "g8")
				performMove(moveKingState, "h8", "f8")
			game.turn == "w" ->
				moveKingState = Map.put(game, :whiteKingSpace, newLocation)
				performMove(moveKingState, oldLocation, newLocation)
			game.turn == "b" ->
				moveKingState = Map.put(game, :blackKingSpace, newLocation)
				performMove(moveKingState, oldLocation, newLocation)
		end
	end

	# Must set enPassantSquare, check for promotion
	def pawnMove(game, oldLocation, newLocation) do
		oldLocationAtom = String.to_atom(oldLocation)
		newLocationAtom = String.to_atom(newLocation)
		position = game.position
		piece = cond do
			game.turn == "w" && String.at(newLocation, 1) == "8" ->
				"wQ"
			game.turn == "w" && String.at(newLocation, 1) == "8" ->
				"wQ"
			game.turn == "b" && String.at(newLocation, 1) == "1" ->
				"bQ"
			game.turn == "b" && String.at(newLocation, 1) == "1" ->
				"bQ"
			true ->
				position[oldLocationAtom]
		end
		removePiece = Map.delete(position, oldLocationAtom)
		newPosition = Map.put(removePiece, newLocationAtom, piece)
		newGameState = Map.put(game, :position, newPosition)
		newGameState
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
		targetSpaceKey = String.to_atom(targetSpace)
		cond do
			size == 0 ->
				false # No diagonal contains target and start space, illegal move
			Map.has_key?(position, targetSpaceKey) -> # contains a piece on target spot
				piece = position[targetSpaceKey]
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
		targetSpaceKey = String.to_atom(targetSpace)
		cond do
			size == 0 ->
				false # No straight contains target and start space, illegal move
			Map.has_key?(position, targetSpaceKey) -> # contains a piece on target spot
				piece = position[targetSpaceKey]
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
		targetSpaceKey = String.to_atom(targetSpace)
		cond do
			!Enum.member?(listKnightMoves, targetSpace) -> # is not a valid move from current position
				false
			Map.has_key?(position, targetSpaceKey) -> # contains a piece on target spot
				piece = position[targetSpaceKey]
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

	# Will need to run a helper function to make sure king isn"t moving into check
	# TODO-- Make sure king isnt castling through check
	def isLegalKingMove(game, targetSpace, startSpace, color, inCheck) do
		files = "abcdefgh"
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
			startSpace == "e1" && targetSpace == "g1" && !inCheck ->
				if color == "w" && game.whiteKingsideCastle do
					spaceAvailable(position, "f1") && spaceAvailable(position, "g1")
				else
				false
				end
			startSpace == "e1" && targetSpace == "c1" && !inCheck ->
				if color == "w" && game.whiteQueensideCastle do
					spaceAvailable(position, "d1") && spaceAvailable(position, "c1") && spaceAvailable(position, "b1")
				else
				false
				end
			startSpace == "e8" && targetSpace == "g8" && !inCheck ->
				if color == "b" && game.blackKingsideCastle do
					spaceAvailable(position, "f8") && spaceAvailable(position, "g8")
				else
				false
				end
			startSpace == "e8" && targetSpace == "c8" && !inCheck ->
				if color == "b" && game.blackQueensideCastle do
					spaceAvailable(position, "d8") && spaceAvailable(position, "c8") && spaceAvailable(position, "b8")
				else
				false
				end
			abs(startFileIndex - targetFileIndex) < 2 && abs(startRank - targetRank) < 2 -> # Move must be within one space in any direction
				if spaceAvailable(position, targetSpace) do
					true
				else
					(String.at(position[String.to_atom(targetSpace)], 0) != color)
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
		space1 = [changeFile(changeRank(space, 1), 2)]
		space2 = [changeFile(changeRank(space, -1), 2)]
		space3 = [changeFile(changeRank(space, 1), -2)]
		space4 = [changeFile(changeRank(space, -1), -2)]
		space5 = [changeFile(changeRank(space, 2), 1)]
		space6 = [changeFile(changeRank(space, 2), -1)]
		space7 = [changeFile(changeRank(space, -2), 1)]
		space8 = [changeFile(changeRank(space, -2), -1)]
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
		space = String.to_atom(Enum.at(squares, 0))
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
		files = "abcdefgh"
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
				""
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
		files = "abcdefgh"
		fileString = String.at(space, 0)
		fileIndexMatch = :binary.match(files, fileString)
		fileIndex = elem(fileIndexMatch, 0)
		rankString = String.at(space, 1)
		cond do
			(fileIndex + direction < 0) || (fileIndex + direction > 7) -> # bad case
				""
			true ->
				newFileIndex = fileIndex + direction
				newFile = String.at(files, newFileIndex)
				newFileIndexString = Integer.to_string(newFile)
				newSpaceString = newFileIndexString + rankString
				newSpaceString
		end
	end
	
	# Return true if the space is empty
	def spaceAvailable(position, space) do
		key = String.to_atom(space)
		if Map.has_key?(position, key) do # Is this space in the position object
			false
		else # Must be empty
			true
		end
	end

	# TODO-- change this to fit format of others? (Use isLegalDiagonal/StraightMove()?)
	def listLegalPawnMoves(position, color, startSpace, enPassantSquare) do
		forwardSpace = cond do
			color == "w" ->
				changeRank(startSpace, 1)
			true ->
				changeRank(startSpace, -1)
		end
		doubleSpace = cond do
			color == "w" ->
				changeRank(startSpace, 2)
			true ->
				changeRank(startSpace, -2)
		end
		leftCapture = cond do
			color == "w" ->
				changeRank(changeFile(startSpace, -1), 1)
			true ->
				changeRank(changeFile(startSpace, -1), -1)
		end
		rightCapture = cond do
			color == "w" ->
				changeRank(changeFile(startSpace, 1), 1)
			true ->
				changeRank(changeFile(startSpace, 1), -1)
		end
		

		# Check forward moves
		moves = cond do 
			spaceAvailable(position, forwardSpace) && spaceAvailable(position, doubleSpace) ->
				Enum.concat([[forwardSpace], [doubleSpace]])
			spaceAvailable(position, forwardSpace) ->
				[forwardSpace]
			true ->
				[]
		end

		leftCaptureKey = String.to_atom(leftCapture)
		rightCaptureKey = String.to_atom(rightCapture)
		
		# Check captures
		leftCapMoves = cond do
			leftCapture == "" ->
				moves
			(position[leftCaptureKey] != nil) && String.at(position[leftCaptureKey], 0) == enemyColor(color) ->
				Enum.concat([moves, [leftCapture]])
			(enPassantSquare == leftCapture) ->
				Enum.concat([moves, [leftCapture]])
			true ->
				moves
		end

		rightCapMoves = cond do
			rightCapture == "" ->
				leftCapMoves
			(position[rightCaptureKey] != nil) && String.at(position[rightCaptureKey], 0) == enemyColor(color) ->
				Enum.concat([leftCapMoves, [rightCapture]])
			(enPassantSquare == rightCapture) ->
				Enum.concat([leftCapMoves, [rightCapture]])
			true ->
				leftCapMoves
		end

		rightCapMoves
	end	

	######################
	# GAME STATE HELPERS #
	######################
	
	# Return full game state 
	def checkGameState(game) do
		kingSpace = if game.turn == "b" do
			game.whiteKingSpace
		else
			game.blackKingSpace
		end
		newState = Map.put(game, :isCheck, isCheck(game.position, game.turn, kingSpace))
		gameOver = (isCheckMate(game.position, game.turn, kingSpace) || isStaleMate(game.position, game.turn, kingSpace))
		newState1 = Map.put(newState, :gameOver, gameOver)
		newState1
	end

	# Determine whether given color has any legal moves
	def hasLegalMoves(position, color, kingSpace) do
		pieces = Map.to_list(position)
		moves = Enum.map(pieces, fn({k, v}) ->
			if String.at(v, 0) == color do
				piece = String.at(v, 1)
				key = to_string(k)
				cond do
					piece == "P" ->
						Enum.map(everySquareOnBoard([], "a", 1), fn(x) ->
							isLegalPawnMove(position, x, key, color, "")
						end)
					piece == "R" ->
						Enum.map(everySquareOnBoard([], "a", 1), fn(x) ->
							isLegalStraightMove(position, x, key, color)
						end)
					piece == "N" ->
						Enum.map(everySquareOnBoard([], "a", 1), fn(x) ->
							isLegalKnightMove(position, x, key, color)
						end)
					piece == "B" ->
						Enum.map(everySquareOnBoard([], "a", 1), fn(x) ->
							isLegalDiagonalMove(position, x, key, color)
						end)
					piece == "Q" ->
						Enum.map(everySquareOnBoard([], "a", 1), fn(x) ->
							isLegalQueenMove(position, x, key, color)
						end)
					piece == "K" ->
						Enum.map(everySquareOnBoard([], "a", 1), fn(x) ->
							isLegalKingMove(position, x, key, color, isCheck(position, color, kingSpace))
						end)
				end
			end 
		end)
		anyMoves = Enum.map(moves, fn(x) -> 
			Enum.member?(x, true)
		end)
		Enum.member?(anyMoves, true)
	end

	# Tough function: Determine whether king is in check
	# - Check all opponent pieces and see if they could move to the king"s space
	# Color is whose turn it is (white moving, see if white king is in check)
	def isCheck(position, color, kingSpace) do
		
		enemyColor = enemyColor(color)
		pieces = Map.to_list(position)
		# king = "#{color}K"
		checks = Enum.map(pieces, fn({k, v}) ->
			if String.at(v, 0) == enemyColor do
				piece = String.at(v, 1)
				key = to_string(k)
				cond do
					piece == "P" ->
						isLegalPawnMove(position, kingSpace, key, color, "")
					piece == "R" ->
						isLegalStraightMove(position, kingSpace, key, color)
					piece == "N" ->
						isLegalKnightMove(position, kingSpace, key, color)
					piece == "B" ->
						isLegalDiagonalMove(position, kingSpace, key, color)
					piece == "Q" ->
						isLegalQueenMove(position, kingSpace, key, color)
					# Check to make sure cant move next to opponent king
					piece == "K" ->
						files = "abcdefgh"
						# king
						startFileString = String.at(key, 0)
						startFileIndex = elem(:binary.match(files, startFileString), 0)
						startRank = String.to_integer(String.at(key, 1))
						# target
						targetFileString = String.at(kingSpace, 0)
						targetFileIndex = elem(:binary.match(files, targetFileString), 0)
						targetRank = String.to_integer(String.at(kingSpace, 1))
						(abs(startFileIndex - targetFileIndex) < 2 && abs(startRank - targetRank) < 2)
				end
			end 
		end)
		Enum.member?(checks, true)
	end

	# Determines if the position is checkmate for given color
	# If king is in check, validate whether king is in check after all possible moves for given color 
	def isCheckMate(position, color, kingSpace) do
		isCheck(position, color, kingSpace) && !hasLegalMoves(position, color, kingSpace)
	end

	# Opposite of checkmate function-- king is not in check, but all legal moves would place him in check
	def isStaleMate(position, color, kingSpace) do
		!isCheck(position, color, kingSpace) && !hasLegalMoves(position, color, kingSpace)
	end

	# Helper function
	# Return opponents color
	def enemyColor(color) do
		if color == "w" do
			"b"
		else
			"w"
		end
	end

	# Return an enum of every square on the board
	def everySquareOnBoard(squares, file, rank) do
		files = "abcdefgh"
		fileIndex = elem(:binary.match(files, file), 0)
		nextFile = cond do
			file == "h" ->
				"a"
			true ->
				String.at(files, fileIndex + 1)
		end
		cond do
			rank == 8 && file == "h" ->
				squares
			file == "h" ->
				everySquareOnBoard(Enum.concat([squares, ["#{file}#{rank}"]]), "a", rank + 1)
			true ->
				everySquareOnBoard(Enum.concat([squares, ["#{file}#{rank}"]]), nextFile, rank)
		end
	end

  ####################
	### INITIALIZERS ###
	####################

	# hard coded start position as a position object, easily usable by chessboard.js library
	# when moving pieces from squares, be sure to delete the key from the map 
  def startPosition() do
    %{
        a1: "wR",
        b1: "wN",
        c1: "wB",
        d1: "wQ",
        e1: "wK",
        f1: "wB",
        g1: "wN",
        h1: "wR",
        a2: "wP",
        b2: "wP",
        c2: "wP",
        d2: "wP",
        e2: "wP",
        f2: "wP",
        g2: "wP",
        h2: "wP",
        a8: "bR",
        b8: "bN",
        c8: "bB",
        d8: "bQ",
        e8: "bK",
        f8: "bB",
        g8: "bN",
        h8: "bR",
        a7: "bP",
        b7: "bP",
        c7: "bP",
        d7: "bP",
        e7: "bP",
        f7: "bP",
        g7: "bP",
        h7: "bP"
    }
  end

end