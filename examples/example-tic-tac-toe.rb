template = <<~HTML
  <div class="app-container">
    <h1>{{ title }}</h1>
    <h2>{{ status_text }}</h2>
    
    <div class="board">
      <button class="cell" @click="click_0_0">{{ cell[0][0] }}</button>
      <button class="cell" @click="click_0_1">{{ cell[0][1] }}</button>
      <button class="cell" @click="click_0_2">{{ cell[0][2] }}</button>
      <button class="cell" @click="click_1_0">{{ cell[1][0] }}</button>
      <button class="cell" @click="click_1_1">{{ cell[1][1] }}</button>
      <button class="cell" @click="click_1_2">{{ cell[1][2] }}</button>
      <button class="cell" @click="click_2_0">{{ cell[2][0] }}</button>
      <button class="cell" @click="click_2_1">{{ cell[2][1] }}</button>
      <button class="cell" @click="click_2_2">{{ cell[2][2] }}</button>
    </div>
    
    <!-- Always display the reset button -->
    <div>
      <button class="reset-btn" @click="reset_game">Reset Game</button>
    </div>
  </div>
HTML

# Define the initial state with a 2D array (3x3 grid)
state = {
  title: "rb-wasm-vdom Example App (Tic-Tac-Toe)",
  cell: [
    ["", "", ""],
    ["", "", ""],
    ["", "", ""]
  ],
  status_text: "Next: O",
  current_player: "O",
  is_game_over: false
}

# Dynamically create click events for the 3x3 grid
methods = {
  # Reset the game state to its initial values
  reset_game: -> (e, s){
    begin
      s[:cell] = [
        ["", "", ""],
        ["", "", ""],
        ["", "", ""]
      ]
      s[:current_player] = "O"
      s[:status_text] = "Next: O"
      s[:is_game_over] = false

    rescue => e
      RbWasmVdom::JSConsole.print_error(e)
    end
  }
}

def click_cell(row:, col:, s:)
  # Do nothing if the game is already over
  return if s[:is_game_over]

  # Do nothing if the cell is already occupied
  current_board = s[:cell]
  return if current_board[row][col] != ""

  # To ensure reactivity, duplicate the 2D array and reassign it to state
  new_board = current_board.map(&:dup)
  new_board[row][col] = s[:current_player]
  s[:cell] = new_board

  # Check for a winner
  winner = nil

  3.times do |i|
    # Check horizontal rows
    if new_board[i][0] != "" && new_board[i][0] == new_board[i][1] && new_board[i][1] == new_board[i][2]
      winner = new_board[i][0]
    end
    # Check vertical columns
    if new_board[0][i] != "" && new_board[0][i] == new_board[1][i] && new_board[1][i] == new_board[2][i]
      winner = new_board[0][i]
    end
  end

  # Check diagonals
  if new_board[0][0] != "" && new_board[0][0] == new_board[1][1] && new_board[1][1] == new_board[2][2]
    winner = new_board[0][0]
  end
  if new_board[0][2] != "" && new_board[0][2] == new_board[1][1] && new_board[1][1] == new_board[2][0]
    winner = new_board[0][2]
  end

  # Check for a draw (if no empty strings remain)
  empty_cell_count = new_board.flatten.inject(0) { |count, val| val == "" ? count + 1 : count }
  is_draw = empty_cell_count == 0

  # Update game status
  if winner
    s[:status_text] = "#{winner} Wins!"
    s[:is_game_over] = true
  elsif is_draw
    s[:status_text] = "Draw!"
    s[:is_game_over] = true
  else
    s[:current_player] = s[:current_player] == "O" ? "X" : "O"
    s[:status_text] = "Next: #{s[:current_player]}"
  end

rescue => e
  RbWasmVdom::JSConsole.print_error(e)
end

# Dynamically create click events for the 3x3 grid
3.times do |row|
  3.times do |col|
    methods["click_#{row}_#{col}".to_sym] = -> (e, s){
      click_cell(row:, col:, s:)
    }
  end
end

RbWasmVdom.create_app("#app", template: template, state: state, methods: methods)
