require "guessr/version"
require "set"
require "pry"
require "camping"

Camping.goes :Guessr

module Guessr
  module Models

    class NumberGuessingGame < Base
    end

    class Player < Base
      validates :name, presence: true, uniqueness: true
      has_many :number_guessing_games
      # alternately: validates :name, presence: true
    end

    class NumberGuessingGame
      validates :answer, presence: true
      belongs_to :player
    end

    class Hangman < Base
      validates :answer, presence: true,
        format: { with: /\A[a-z]+\z/, message: "only lowercase words allowed"}
      serialize :guesses
      before_save :set_finished!, if: :finished?

      def guess_letter(letter)
        self.guesses.add(letter)
        self.turns -= 1 unless self.answer.include?(letter)
      end

      def finished?
        self.turns.zero? || self.answer.chars.all? { |l| self.guesses.include?(l) }
      end

      private
      def set_finished!
        self.finished = true
      end
    end

    class BasicSchema < V 1.0
      def self.up
        create_table Player.table_name do |t|
          t.string :name
          t.string :game
          t.timestamps
        end

        create_table Hangman.table_name do |t|
          t.integer :turns, :default => 7
          t.string :answer
          t.string :guesses
          t.boolean :finished
          t.timestamps
        end
      end

      def self.down
        drop_table Player.table_name
        drop_table Hangman.table_name
      end
    end

    class AddPlayerIdToHangman < V 1.1
      def self.up
        add_column Hangman.table_name, :player_id, :integer
      end

      def self.down
        remove_column Hangman.table_name, :player_id
      end
    end

    class AddNumberGuessingGame < V 1.2
      def self.up
        create_table NumberGuessingGame.table_name do |t|
          t.integer :player_id
          t.integer :answer
          t.integer :guess
          t.timestamps
        end
      end

      def self.down
        drop_table NumberGuessingGame.table_name
      end
    end

    class RemoveGameFromPlayerTable < V 1.3
      def self.up
        remove_column Player.table_name, :game
      end

      def self.down
        raise ActiveRecord::IrreversibleMigration
      end
    end

    class AddFinishedToGuessingGame < V 1.4
      def self.up
        add_column NumberGuessingGame.table_name, :finished, :boolean
        NumberGuessingGame.find_each do |game|
          game.finished = game.answer == game.guess
          game.player_id = nil
          # other things
          game.save
          #game.update_attribute(:finished, game.answer == game.finished)
        end
      end

      def self.down
        remove_column NumberGuessingGame.table_name, :finished
      end
    end
  end
end

def Guessr.create
  Guessr::Models.create_schema
end

def number_game(game_id=nil)
  if game_id
    game = Guessr::Models::NumberGuessingGame.find(game_id)
    player = Guessr::Models::Player.find(game.player_id)
    puts "You last guessed #{game.guess}. I don't care if it was too high or low."
  else
    player = Guessr::Models::Player.first
    game = Guessr::Models::NumberGuessingGame.create(:player_id => player.id, :answer => rand(1..100))
  end
  puts "Select a number between 1 - 100."
  while game.guess != game.answer
    game.update_attribute(:guess, gets.chomp.to_i)
    if game.guess.zero?
      puts "Thanks for playing!"
      exit
    elsif  game.guess > game.answer
      puts "That number is too high. Guess again!"
    elsif game.guess < game.answer
      puts "That number is too low. Guess again!"
    else
      puts "That is correct! You've won!"
    end
  end
end

def scoreboard
  result = {}
  Guessr::Models::Player.find_each do |p|
    result[p.name] = 0
    Guessr::Models::NumberGuessingGame.where(:player_id => p.id).each do |g|
      result[p.name] += 1 if g.finished
    end
  end
  puts "Player    |     Score"
  result.sort_by{ |k, v| -v }.each { |k, v| puts "'#{k}': #{v}"}
end

def better_scoreboard
  result = {}
  Guessr::Models::Player.find_each do |player|
    result[player.name] = 0
    player.number_guessing_games.each do |game|
      result[player.name] += 1 if game.finished
    end
  end
  puts "Player    |     Score"
  result.sort_by{ |k, v| -v }.each { |k, v| puts "'#{k}': #{v}"}
end
