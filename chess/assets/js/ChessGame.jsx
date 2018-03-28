import React from 'react';
import ReactDOM from 'react-dom';
import ChessBoard from 'chessboardjs';
import Chess from 'react-chess';
import _ from 'underscore';

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

        if this.state.gameOver {
            this.channel.push()
        }

        this.setState(view.game);
    }

    handleMove(piece, oldLocation, newLocation) {
        var originalState = Object.assign({}, this.state.position);
        this.channel.push("move", { oldLocation: oldLocation, newLocation: newLocation })
            .receive("ok", this.gotView.bind(this));
        if (_.isEqual(originalState, this.state.position)) {
            location.reload();
        }
    }


    render() {
        var handleMove = this.handleMove.bind(this);
        var pieceList = this.state.position;
        return (
            <div style={{ width: '500px' }}>
                <Chess pieces={pieceList} onMovePiece={handleMove} />
            </div>
        );
    }
}