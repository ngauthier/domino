class TestApplication
  def call(env)
    [200, { 'Content-Type' => 'text/plain' }, [response(env)]]
  end

  def response(env)
    case env.fetch('PATH_INFO')
    when '/'
      root
    when '/people/23/edit'
      params = {
        'person' => {
          'id' => 23,
          'name' => 'Alice',
          'last_name' => 'Cooper',
          'bio' => 'Alice is fun',
          'fav_color' => 'blue',
          'age' => 23,
          'vehicles' => []
        }, 'is_human' => false
      }
      edit params
    when '/people/23'
      params = Rack::Utils.parse_nested_query(env.fetch('rack.input').read)
      edit params.merge(flash: "Person updated successfully.")
    end
  end

  def root
    <<-HTML
      <html>
        <body>
          <h1>Here are people and animals</h1>
          <div id='people'>
            <div class='person active' data-rank="1" data-uuid="e94bb2d3-71d2-4efb-abd4-ebc0cb58d19f">
              <h2 class='name'>Alice</h2>
              <p class='last-name'>Cooper</p>
              <p class='bio'>Alice is fun</p>
              <p class='fav-color'>Blue</p>
              <p class='age'>23</p>
            </div>
            <div class='person' data-rank="3" data-uuid="05bf319e-8d6a-43c2-be37-2dad8ddbe5af">
              <h2 class='name'>Bob</h2>
              <p class='last-name'>Marley</p>
              <p class='bio'>Bob is smart</p>
              <p class='fav-color'>Red</p>
              <p class='age'>52</p>
            </div>
            <div class='person' data-rank="2" data-uuid="4abcdeff-1d36-44a9-a05e-8fc57564d2c4">
              <h2 class='name'>Charlie</h2>
              <p class='last-name'>Murphy</p>
              <p class='bio'>Charlie is wild</p>
              <p class='fav-color'>Red</p>
            </div>
            <div class='person' data-rank="7" data-blocked data-uuid="2afccde0-5d13-41c7-ab01-7f37fb2fe3ee">
              <h2 class='name'>Donna</h2>
              <p class='last-name'>Summer</p>
              <p class='bio'>Donna is quiet</p>
            </div>
          </div>
          <div id='animals'></div>
          <div id='receipts'>
            <div class='receipt' id='receipt-72' data-store='ACME'></div>
          </div>
        </body>
      </html>
    HTML
  end

  def edit(params = { 'person' => {} })
    person = params['person']
    <<-HTML
      <html>
        <body>
          <div class="flash">#{params[:flash]}</div>
          <h1>Edit Person</h1>

          <form action="/people/#{person['id']}" method="post" class="person">
            <div class="input name">
              <label for="person_name">First Name</label>
              <input type="text" id="person_name" name="person[name]" value="#{person['name']}" />
            </div>

            <div class="input last_name">
              <label for="person_name">Last Name</label>
              <input type="text" id="person_last_name" name="person[last_name]" value="#{person['last_name']}" />
            </div>

            <div class="input bio">
              <label for="person_bio">Biography</label>
              <textarea id="person_bio" name="person[bio]">#{person['bio']}</textarea>
            </div>

            <div class="input fav_color">
              <label for="person_fav_color">Favorite Color</label>
              <select id="person_fav_color" name="person[fav_color]">
                <option value>- Select a Color -</option>
                <option value="red" #{'selected="selected"' if person['fav_color'] == 'red'}>Red</option>
                <option value="blue" #{'selected="selected"' if person['fav_color'] == 'blue'}>Blue</option>
                <option value="green" #{'selected="selected"' if person['fav_color'] == 'green'}>Green</option>
              </select>
            </div>

            <div class="input age">
              <label for="person_age">Biography</label>
              <input type="number" min="0" step="1" id="person_age" name="person[age]" value="#{person['age']}" />
            </div>

            <div class="input is_human">
              <input type="hidden" name="is_human" value="0">
              <label for="is_a_human">
                <input id="is_a_human" type="checkbox" name="is_human" value="1" #{'checked' if params['is_human']}>
                I'm a human
              </label>
            </div>

            <div class="input vehicles">
              <label for="person_vehicles_bike"><input id="person_vehicles_bike" type="checkbox" name="person[vehicles][]" value="Bike" #{'checked' if person['vehicles'].include?('Bike')}>Bike</label>
              <label for="person_vehicles_car"><input id="person_vehicles_car" type="checkbox" name="person[vehicles][]" value="Car" #{'checked' if person['vehicles'].include?('Car')}>Car</label>
            </div>

            <div class="input allergies">
              <label for="allergies">Allergies</label>
              <select id="allergies" name="allergies" multiple="multiple">
                <option value>None</option>
                <option value="peanut" #{'selected="selected"' if Array(params['allergies']).include?('peanut')}>Peanut</option>
                <option value="corn" #{'selected="selected"' if Array(person['allergies']).include?('corn')}>Corn</option>
                <option value="wheat" #{'selected="selected"' if Array(person['allergies']).include?('wheat')}>Wheat</option>
              </select>
            </div>

            <div class="actions">
              <input type="submit" name="commit" value="Update Person" />
            </div>
          </form>
        </body>
      </html>
    HTML
  end
end

Capybara.app = TestApplication.new
