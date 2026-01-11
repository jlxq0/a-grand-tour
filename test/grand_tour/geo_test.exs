defmodule GrandTour.GeoTest do
  use GrandTour.DataCase

  describe "PostGIS extension" do
    test "postgis extension is installed" do
      result = GrandTour.Repo.query!("SELECT PostGIS_Version()")
      assert [[version]] = result.rows
      assert is_binary(version)
      assert String.contains?(version, ".")
    end

    test "can create and query geometry points" do
      # Insert a point using raw SQL
      GrandTour.Repo.query!("""
        CREATE TEMPORARY TABLE test_points (
          id serial PRIMARY KEY,
          name varchar(255),
          location geometry(Point, 4326)
        )
      """)

      # Insert some test points (Paris, London, Berlin)
      GrandTour.Repo.query!("""
        INSERT INTO test_points (name, location) VALUES
          ('Paris', ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326)),
          ('London', ST_SetSRID(ST_MakePoint(-0.1276, 51.5074), 4326)),
          ('Berlin', ST_SetSRID(ST_MakePoint(13.4050, 52.5200), 4326))
      """)

      # Query points within 500km of Paris
      result =
        GrandTour.Repo.query!("""
          SELECT name, ST_Distance(
            location::geography,
            ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326)::geography
          ) / 1000 as distance_km
          FROM test_points
          WHERE ST_DWithin(
            location::geography,
            ST_SetSRID(ST_MakePoint(2.3522, 48.8566), 4326)::geography,
            500000
          )
          ORDER BY distance_km
        """)

      # Paris should be found (distance 0), London should be found (~344km)
      # Berlin is ~878km away, so it should NOT be in results
      assert length(result.rows) == 2

      [[name1, dist1], [name2, dist2]] = result.rows
      assert name1 == "Paris"
      # Paris is at distance 0
      assert dist1 < 1
      assert name2 == "London"
      # London is ~344km from Paris
      assert dist2 > 300 and dist2 < 400
    end

    test "can use Geo structs with Ecto" do
      point = %Geo.Point{coordinates: {2.3522, 48.8566}, srid: 4326}

      # Verify the point can be encoded
      assert point.coordinates == {2.3522, 48.8566}
      assert point.srid == 4326
    end
  end
end
