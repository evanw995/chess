import React from 'react';
import ReactDOM from 'react-dom';
import { ChessGame } from './ChessGame.jsx';

export default function run_gamePage(root, channel) {
  ReactDOM.render(<GamePage channel={channel} />, root);
}

class GamePage extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      channel: props.channel,
    };
  }

  render() {
    return (
      <div id="chessGame">
        <ChessGame channel={this.props.channel}/>
      </div>
    );
  }
}
