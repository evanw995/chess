import React from 'react';
import ReactDOM from 'react-dom';
import ChessBoard from 'chessboardjs';
import $ from 'jquery';
import Chess from 'react-chess';

window.$ = $
window.jQuery = $

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
        // this.handleGuess = this.handleGuess.bind(this);
    }

    gotView(view) {
        console.log("New view", view);
        this.setState(view.game);
    }

    handleMove(piece, oldLocation, newLocation) {
        console.log(newLocation);
        console.log(oldLocation);
        this.channel.push("move", { oldLocation: oldLocation, newLocation: newLocation })
            .receive("ok", this.gotView.bind(this));
    }


    render() {
        var handleMove = this.handleMove.bind(this);
        var pieceList = this.state.position;
        return (
            <div>
                <Chess pieces={pieceList} onMovePiece={handleMove} />
            </div>
        );
    }

    // componentDidMount() {
    //     var cfg = {
    //         draggable: true,
    //         position: 'start',
    //         onDragMove: onDragMove,
    //         sparePieces: true
    //     };
    //     setTimeout(function() {
    //         var board1 = new ChessBoard('board1', 'start');
    //     }, 10);
    // }
    // setTimeout(function() {
        //     var board1 = new ChessBoard('board1', 'start');
        //     board1.position = this.state.position
        // }, 100);
        
        // // var board = ChessBoard("board", cfg);
        // // <div id="placeholder">
        // //         Placeholder.
        // //     </div>
         // var cfg = {
        //     draggable: true,
        //     position: 'start',
        //     onDragMove: onDragMove,
        //     sparePieces: true
        // };
        
}