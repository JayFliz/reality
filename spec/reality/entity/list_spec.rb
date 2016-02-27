module Reality
  describe Entity::List do
    def make_page(name)
      double(title: name, infobox: double(name: 'Infobox country')).tap{|d|
        allow(d).to receive(:fetch).and_return(nil)
      }
    end

    def make_data(name)
      double(predicates: {})
    end

    describe :initialize do
      context 'from names' do
        subject{Entity::List.new('Argentina', 'Bolivia', 'Chile')}
        it{should all be_an Entity}
        it{should all satisfy{|e| !e.loaded?}}
        it{should be_kind_of Array}
      end

      context 'from entities' do
        subject{Entity::List.new(Entity.new('Argentina'), Entity.new('Bolivia'), Entity.new('Chile'))}
        it 'should be coerced' do
          expect(subject.map(&:name)).to eq ['Argentina', 'Bolivia', 'Chile']
        end
      end
    end

    describe :load! do
      subject(:list){Entity::List.new('Argentina', 'Bolivia', 'Chile')}
      
      context 'when everything is loaded successfully' do
        let(:wikipedia){double}

        before{
          allow(Infoboxer).to receive(:wp).and_return(wikipedia)
          expect(wikipedia).to receive(:get).
            with('Argentina', 'Bolivia', 'Chile').
            and_return([make_page('Argentina'), make_page('Bolivia'), make_page('Chile')])

          expect(Wikidata::Entity).to receive(:fetch_list).
            with('Argentina', 'Bolivia', 'Chile').
            and_return([make_data('Argentina'), make_data('Bolivia'), make_data('Chile')])

          list.load!
        }
        it{should all be_loaded}
      end

      context 'when some entities are not found' do
      end
    end

    describe :inspect do
      context 'not loaded entities' do
        subject{Entity::List.new('Argentina', 'Bolivia', 'Chile')}

        its(:inspect){should == '#<Reality::Entity::List[Argentina?, Bolivia?, Chile?]>'}
      end

      context 'loaded entities' do
        let(:entity){Entity.new('Argentina', wikipage: make_page('Argentina'), wikidata: make_data('Argentina'))}
        subject{Entity::List.new(entity)}

        its(:inspect){should == '#<Reality::Entity::List[Argentina]>'}
      end
    end

    describe 'array-ish behavior' do
      subject(:list){Entity::List.new('Argentina', 'Bolivia', 'Chile')}
      
      it 'tries to preserve type' do
        expect(list.select{|e| e.name.include?('a')}).to be_a Entity::List
        expect(list.reject{|e| e.name.include?('a')}).to be_a Entity::List
        expect(list.sort_by(&:name)).to be_a Entity::List
        expect(list.map(&:itself)).to be_a Entity::List
        expect(list.first(2)).to be_a Entity::List
      end

      it 'drops type when inappropriate' do
        expect(list.first).to be_a Entity
        expect(list.map(&:name)).not_to be_a Entity::List
      end
    end
  end
end