require "guessr/version"
require "set"
require "camping"

Camping.goes :Guessr

module Guessr
  module Models

    class Player < Base
      validates :name, presence: true, uniqueness: true
      # alternately: validates :name, presence: true
    end

    class NumberGuessingGame < Base
      validates :answer, presence: true

      intro = puts "Select a number between 1 - 100."

      answer = rand(1..100)
      guess = ""

      def game(guess,answer)
        while guess != answer do
          guess = gets.chomp.to_i
          if guess == 0
            puts "That is not a valid option. Select a number between 1 - 100."
          elsif  guess > answer
            puts "That number is too high. Guess again!"
          elsif guess < answer
            puts "That number is too low. Guess again!"
          else
            puts "That is correct! You've won!"
          end
        end
      end
    end

    class Hangman < Base
      validates :answer, presence: true,
        format: { with: /^[a-z]+$/, message: "only lowercase words allowed"}
      serialize :guesses
      before_save :set_finished!, if: :finished?

      def guess_letter(letter)
        self.guesses.add(letter)
        self.turns -= 1 unless self.answer.include?(letter)
      end

      private
      def finished?
        self.turns.zero? || self.answer.chars.all? { |l| self.guesses.include?(l) }
      end

      def set_finished!
        self.finished = true
      end
    end

    class BasicSchema < V 1.0
      def self.up
        create_table Player.table_name do |t|
          t.string :name
          t.string :game #want to add game name column
          t.timestamps
        end

        create_table NumberGuessingGame.table do |t|
          t.integer :answer
          t.integer :guess
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
        drop_table NumberGuessingGame.table_name
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

    class AddPlayerIdToNumberGuessingGame < V 1.1
      def self.up
        add_column NumberGuessingGame.table_name, :player_id, :integer
      end

      def self.down
        remove_column NumberGuessingGame.table_name, :player_id
      end
    end

  end
end

def Guessr.create
  Guessr::Models.create_schema
end
