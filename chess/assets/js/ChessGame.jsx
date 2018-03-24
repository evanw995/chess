import React from 'react';
import ReactDOM from 'react-dom';

export class ChessGame extends React.Component {

    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {
            position: [],
            gameOver: false, 
            turn: 'w', 
            inCheck: false
        }

        this.channel.join()
            .receive("ok", this.gotView.bind(this))
            .receive("error", resp => { console.log("Unable to join", resp) });

        // handleGuess must be bound in constructor
        // in order to pass down to child components (Blocks) successfully
        this.handleGuess = this.handleGuess.bind(this);
    }

    gotView(view) {
        console.log("New view", view);
        this.setState(view.game);
    }

    handleMove(newLocation, oldLocation, piece) {
        this.channel.push("move", { oldLocation: oldLocation, newLocation: newLocation, piece: piece }) // await?
            .receive("ok", this.gotView.bind(this));
    }

    render() {
        var onDragMove = function(newLocation, oldLocation, source,
                        piece, position, orientation) {
                            handleMove(newLocation, oldLocation, piece);
            };

        var cfg = {
            draggable: true,
            position: 'start',
            onDragMove: onDragMove,
            sparePieces: true
        };
        var board = ChessBoard('board', cfg);
        return (
            <div id="board" style="width: 400px"></div>
        );
    }
}