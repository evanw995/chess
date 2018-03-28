import React from 'react';
import ReactDOM from 'react-dom';
import Chess from 'react-chess';
import _ from 'underscore';
import Fade from 'reactstrap';

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
    }

    gotView(view) {
        console.log("New view", view);

        if (view.game.gameOver) {
            if (view.game.inCheck) {
                if (view.game.turn == "w") {
                    alert("Game Over: Black wins by checkmate!");
                } else {
                    alert("Game Over: White wins by checkmate!");
                }
            } else {
                alert("Game Over: Stalemate!");
            }
        }

        this.setState(view.game);
    }

    handleMove(piece, oldLocation, newLocation) {
        // var originalState = Object.assign({}, this.state.position);
        this.channel.push("move", { oldLocation: oldLocation, newLocation: newLocation })
            .receive("ok", this.gotView.bind(this));
        // if (_.isEqual(originalState, this.state.position)) {
        //     location.reload();
        // }
        location.reload();
    }

    // winMessage() {
    //     if (this.state.inCheck) {
    //         if (this.state.turn == "w") {
    //             return "Black wins by checkmate!";
    //         } else {
    //             return "White wins by checkmate!";
    //         }
    //     } else {
    //         return "Draw by stalemate!";
    //     }
    // }

    render() {
        var handleMove = this.handleMove.bind(this);
        //        var winMessage = this.winMessage.bind(this);
        var pieceList = this.state.position;
        return (
            //  <div>
            <div style={{ width: '500px' }}>
                <Chess pieces={pieceList} onMovePiece={handleMove} />
            </div>
            // <Fade in={this.state.gameOver}> <span id="over">Game Over!
            //     {winMessage} </span></Fade>
            // </div>
        );
    }
}