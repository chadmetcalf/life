RSpec.describe Cell do
  let(:generation) { instance_double(Generation) }

  it 'has coordinates' do
    expect(subject.coordinates).to be_a(Coordinates)
  end

  it 'has neighbors' do
    allow(subject).to receive(:generation).and_return(generation)
    allow(Neighborhood).to receive(:neighbors).and_return(0)
    expect(subject.neighbors).to eq(0)
  end

  context '#tick!' do
    it 'a lonely cell dies' do
      # Any live cell with fewer than two live neighbours dies,
      # as if caused by under-population.
      allow(Neighborhood).to receive(:neighbors).and_return(1)
      expect(subject.tick!(generation: generation)).to be_nil
    end

    it 'an overcrowded cell dies' do
      # Any live cell with more than three live neighbours dies,
      # as if by overcrowding.
      allow(Neighborhood).to receive(:neighbors).and_return(4)
      expect(subject.tick!(generation: generation)).to be_nil
    end

    it 'a happy cell lives' do
      # Any live cell with two or three live neighbours
      # lives on to the next generation.
      allow(Neighborhood).to receive(:neighbors).and_return(2)
      expect(subject.tick!(generation: generation)).to be(subject)
      allow(Neighborhood).to receive(:neighbors).and_return(3)
      expect(subject.tick!(generation: generation)).to be(subject)
    end
  end
end

RSpec.describe Board do
  it 'contains a generation' do
    expect(subject.generation).to be_a(Generation)
  end

  context '#tick!' do
    it 'results in a new generation' do
      generation  = subject.generation

      expect(subject.generation).to be(generation)
      subject.tick!
      expect(subject.generation).to_not be(generation)
    end
  end

  it '#blank_board is a blank board' do
    expect(subject.blank_board).to eq(
      [[0,0,0,0,0,0,0,0,0,0],
       [0,0,0,0,0,0,0,0,0,0],
       [0,0,0,0,0,0,0,0,0,0],
       [0,0,0,0,0,0,0,0,0,0],
       [0,0,0,0,0,0,0,0,0,0],
       [0,0,0,0,0,0,0,0,0,0],
       [0,0,0,0,0,0,0,0,0,0],
       [0,0,0,0,0,0,0,0,0,0],
       [0,0,0,0,0,0,0,0,0,0],
       [0,0,0,0,0,0,0,0,0,0]])
  end

  it 'draws the board' do
    coords = [Coordinates.new(latitude: 0, longitude: 0),
              Coordinates.new(latitude: 2, longitude: 0),
              Coordinates.new(latitude: 4, longitude: 4)]
    allow(subject).to receive(:generation_coordinates).and_return(coords)

    subject.draw!
  end
end

RSpec.describe Size do
  it 'has a defaut longitude' do
    expect(subject.longitude).to eq(5)
  end

  it 'has a defaut latitude' do
    expect(subject.latitude).to eq(5)
  end
end

RSpec.describe Generation do
  it '.next' do
    subject

    next_generation = Generation.next(subject)

    expect(next_generation).to_not be(subject)
    expect(next_generation).to be_a(Generation)
  end

  it 'is a collection of cells' do
    cell = Cell.new
    subject << cell
    subject << cell.dup
    subject << cell.dup
    expect(subject).to include(cell)
  end

  it '#coordinates is a collection of coordinates' do
    expect(subject.coordinates).to be_an(Array)
  end

  context '#tick!' do
    it 'returns a generation' do
      expect(subject.tick!).to be_a(Generation)
    end

    it 'iterates the generation number' do
      expect(subject.number).to eq(1)
      subject.tick!
      subject.tick!
      subject.tick!
      subject.tick!
      expect(subject.number).to eq(5)
    end

    it 'tells each cell to tick!' do
      cell = Cell.new
      expect(cell).to receive(:tick!)
      subject << cell

      subject.tick!
    end

    it 'is the next generation' do
      subject << (lonely_cell  = instance_double(Cell, neighbors: 1, 'tick!' => nil, coordinates: Coordinates.new) )
      subject << (happy_cell   = instance_double(Cell, neighbors: 2, 'tick!' => instance_double(Cell), coordinates: Coordinates.new) )
      subject << (happy_cell   = instance_double(Cell, neighbors: 3, 'tick!' => instance_double(Cell), coordinates: Coordinates.new) )
      subject << (crowded_cell = instance_double(Cell, neighbors: 4, 'tick!' => nil, coordinates: Coordinates.new) )

      next_generation = subject.tick!

      expect(next_generation.length).to eq(2)
    end

    it 'facilitates reproduction' do
      # Any dead cell with exactly three live neighbours
      # becomes a live cell, as if by reproduction.

      subject << Cell.new(coordinates: Coordinates.new(latitude: 0, longitude: 0))
      subject << Cell.new(coordinates: Coordinates.new(latitude: 2, longitude: 0))
      subject << Cell.new(coordinates: Coordinates.new(latitude: 0, longitude: 2))

      next_generation = subject.tick!

      expect(next_generation.length).to eq(1)
    end
  end
end

RSpec.describe Coordinates do
  it 'has a longitude' do
    expect(subject.longitude).to eq(0)
  end

  it 'has a latitude' do
    expect(subject.latitude).to eq(0)
  end
end

RSpec.describe Neighborhood, focus: true do
  let(:subject)    { Neighborhood.new(generation: generation) }
  let(:generation) { Generation.new }
  let(:coords)     { Coordinates.new(latitude: 1, longitude: 0) }

  it 'requires generation' do
    expect{ Neighborhood.new }.to raise_error(Neighborhood::MissingGenerationError)
  end

  context '#neighbors' do
    it 'requires coordinates' do
      expect{ subject.neighbors }.to raise_error(Neighborhood::MissingCoordinatesError)
    end

    it 'defaults to zero' do
      allow(generation).to receive(:coordinates).and_return([coords])
      expect(subject.neighbors(coordinates: coords)).to eq(0)
    end

    it 'counts existing neighboring coordinates' do
      generation_coords = [
        Coordinates.new(latitude: 0, longitude: 0),
        Coordinates.new(latitude: 2, longitude: 0),
        Coordinates.new(latitude: 5, longitude: 5),
        coords]

      allow(generation).to receive(:coordinates).and_return(generation_coords)
      expect(subject.neighbors(coordinates: coords)).to eq(2)
    end
  end

  it 'returns empty pairs around coordinates' do
    coords = Coordinates.new(latitude: 1, longitude: 1)
    empty_pairs = subject.empty_coordinates_by_longitude_latitude(coordinates: coords)
    expect(empty_pairs[1][1]).to be_nil
    expect(empty_pairs[0][1]).to be_a(Coordinates)
    empty_pair_count = empty_pairs.flat_map{|_,v| v.map{|_,v| v}}.count
    expect(empty_pair_count).to eq(8)
  end
end
