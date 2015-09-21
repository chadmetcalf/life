class Cell
  class TickError < StandardError; end;

  attr_reader :state, :generation

  def initialize(coordinates: default_coordinates)
    @coordinates = coordinates
  end

  def tick!(generation:)
    @generation = generation
    case
    when lonely? || overcrowded?
      return nil
    when happy?
      return self
    end
    fail TickError
  end

  def lonely?
    neighbors < 2
  end

  def overcrowded?
    neighbors > 3
  end

  def happy?
    neighbors == 2 || neighbors == 3
  end

  def neighbors
    @neighbors ||= Neighborhood.neighbors(generation: generation, coordinates: coordinates)
  end

  def coordinates
    @coordinates ||= default_coordinates
  end

  def default_coordinates
    Coordinates.new(longitude: 0, latitude: 0)
  end
end

class Board
  attr_reader :generation, :size

  def initialize(size: nil)
    @size = size || Size.new(latitude: 10, longitude: 10)
    @generation = Generation.new(size: size)
  end

  def tick!
    @generation = Generation.next(generation)
  end

  def draw!
    generation_coordinates.each do |coord|
      filled_board[coord.latitude][coord.longitude] = 1
    end
    filled_board.inspect
  end

  def blank_board
    @blank_board ||= Array.new(size.longitude).map{Array.new(size.latitude, 0)}
  end

  def filled_board
    @filled_board ||= clear_filled_board!
  end

  def clear_filled_board!
    @filled_board = blank_board
  end

  def generation_coordinates
    generation.coordinates
  end
end

class Size
  attr_reader :latitude, :longitude

  def initialize(latitude: 5, longitude: 5)
    @latitude = latitude
    @longitude = longitude
  end
end

class Generation < Array
  def self.next(previous_generation)
    previous_generation.tick!
  end

  attr_reader :number, :size

  def initialize(size: Size.new)
    @size   = size
    @number = 1
  end

  def tick!
    @number += 1
    tick_cells!
    reproduce!
    the_next_generation
  end

  def the_next_generation
    @the_next_generation ||= Generation.new
  end

  def tick_cells!
    each do |cell|
      next_cell = cell.tick!(generation: self)
      next unless next_cell
      the_next_generation << next_cell
    end
  end

  def reproduce!
    empty_coordinates.each do |coords|
      neighbors = neighborhood.neighbors(coordinates: coords)
      case
      when neighbors > 3 || neighbors < 3
        next
      when neighbors == 3
        the_next_generation << Cell.new(coordinates: coords)
      else
      end
    end
  end

  def coordinates
    map(&:coordinates)
  end

  private

  def empty_coordinates
    @empty_coordinates ||= neighbored_empty_coordinates
  end

  def neighbored_empty_coordinates
    @empty_coordinates = []
    neighbored_empty_pairs.each_value do |row|
      row.each_value do |coords|
        @empty_coordinates << coords
      end
    end
    @empty_coordinates
  end

  def neighbored_empty_pairs
    # first do pairs to keep from doubling up
    @neighbored_empty_pairs = {}
    coordinates.each do |coords|
      @neighbored_empty_pairs.merge!(neighborhood.empty_coordinates_by_longitude_latitude(coordinates: coords))
    end
    @neighbored_empty_pairs
  end

  def neighborhood
    Neighborhood.new(generation: self)
  end
end

class Coordinates
  attr_reader :latitude, :longitude

  def initialize(latitude: 0, longitude: 0)
    @latitude  = latitude
    @longitude = longitude
  end
end

class Neighborhood
  class MissingGenerationError  < ArgumentError; end;
  class MissingCoordinatesError < ArgumentError; end;

  def self.neighbors(generation: nil, coordinates: nil)
    neighborhood = new(generation: generation)
    neighborhood.neighbors(coordinates: coordinates)
  end

  attr_reader :coordinates

  def initialize(generation: nil)
    fail MissingGenerationError unless generation.is_a?(Generation)
    @generation  = generation
  end

  def neighbors(coordinates: nil)
    fail MissingCoordinatesError unless coordinates.is_a?(Coordinates)
    @coordinates = coordinates
    count_neighbors
  end

  def empty_coordinates_by_longitude_latitude(coordinates: nil)
    fail MissingCoordinatesError unless coordinates.is_a?(Coordinates)
    @coordinates = coordinates
    empty_pairs = {}
    latitude_range.each do |latitude|
      next if latitude < 0
      next if latitude > generation_size.latitude
      longitude_range.each do |longitude|
        next if latitude == coordinates.latitude && longitude == coordinates.longitude
        next if longitude < 0
        next if longitude > generation_size.longitude
        next if alive_latitude_longitude_pairs[latitude] && alive_latitude_longitude_pairs[latitude][longitude]
        empty_pairs[longitude] ||= {}
        empty_pairs[longitude][latitude] = Coordinates.new(longitude: longitude, latitude: latitude)
      end
    end
    empty_pairs
  end

  private

  def alive_latitude_longitude_pairs
    @alive_latitude_longitude_pairs ||= alive_latitude_longitude_pairs!
  end

  def alive_latitude_longitude_pairs!
    alive_pairs = {}
    countable_coordinates.each do |coords|
      alive_pairs[coords.longitude] ||= {}
      alive_pairs[coords.longitude][coords.latitude] = true
    end
    alive_pairs
  end

  def count_neighbors
    countable_coordinates.select do |coords|
      latitude_range.member?(coords.latitude) && longitude_range.member?(coords.longitude)
    end.length
  end

  def countable_coordinates!
    @countable_coordinates = generation_coordinates
    @countable_coordinates.delete(coordinates)
    @countable_coordinates
  end

  def countable_coordinates
    @countable_coordinates ||= countable_coordinates!
  end

  def generation_coordinates
    @generation.coordinates
  end

  def generation_size
    @generation.size
  end

  def latitude_range
    (coordinates.latitude - 1 .. coordinates.latitude + 1)
  end

  def longitude_range
    (coordinates.longitude - 1 .. coordinates.longitude + 1)
  end
end

class Runner
  def self.go
    raise board.inspect
    5.times do
      puts board.draw!
      sleep(0.5)
      board.tick!
    end
    puts board.draw!
  end

  def self.board
    @board ||= default_board
  end

  def self.default_board
    @board = Board.new(size: default_size)
    default_coordinates.each do |coords|
      @board.generation << Cell.new(coords)
    end
    @board
  end

  def self.default_coordinates
    @default_coordinates ||= built_coordinates
  end

  def self.built_coordinates
    default_lat_longs.flat_map do |latitude, v|
      v.map do |longitude, _|
        Coordinates.new(latitude: latitude, longitude: longitude)
      end
    end
  end

  def self.default_lat_longs
    @default_lat_longs = {}
    rand(10).times do
      @default_lat_longs[rand(default_size.latitude)][rand(default_size.longitude)] = 1
    end
    @default_lat_longs
  end

  def self.default_size
    @size ||= Size.new(latitude: 5, longitude: 5)
  end
end
