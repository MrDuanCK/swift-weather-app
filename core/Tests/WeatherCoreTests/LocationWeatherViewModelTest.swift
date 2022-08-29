import XCTest
@testable import WeatherCore

let fakeLocation = Location(woeId: 0, title: "Fake", latitude: 0.0, longitude: 0.0)
let fakeWeather = Weather(state: .clear, date: Date(), minTemp: 0.0, maxTemp: 0.0,
        temp: 0.0, windSpeed: 0.0, windDirection: 0.0, airPressure: 0.0,
        humidity: 0.0, visibility: 0.0, predictability: 0.0)

class LocationWeatherViewModelTest: XCTestCase {
    
    var viewModel: LocationWeatherViewModel?

    func testLoadSavedLocations() {
        let weatherExpectation = expectation(description: "onWeatherChanged should be called")
        viewModel = createViewModel(weatherExpectation: weatherExpectation)
        wait(for: [weatherExpectation], timeout: 1.0)
        XCTAssert(viewModel != nil)
    }

    func testAddLocationToSaved() {
        let addExpectation = expectation(description: "addLocation should be called")
        viewModel = createViewModel(addExpectation: addExpectation)
        viewModel?.addLocationToSaved(location: fakeLocation)
        wait(for: [addExpectation], timeout: 1.0)
    }

    func testRemoveSavedLocation() {
        let removeExpectation = expectation(description: "removeLocation should be called")
        viewModel = createViewModel(removeExpectation: removeExpectation)
        viewModel?.removeSavedLocation(location: fakeLocation)
        wait(for: [removeExpectation], timeout: 1.0)
    }

    func testWeatherFail() {
        let errorExpectation = expectation(description: "onError should be called")
        viewModel = createViewModel(errorExpectation: errorExpectation)
        viewModel?.weather(location: Location(woeId: 1, title: "fake", latitude: 0.0, longitude: 0.0))
        wait(for: [errorExpectation], timeout: 1.0)
    }

    func createViewModel(addExpectation: XCTestExpectation? = nil,
                          removeExpectation: XCTestExpectation? = nil,
                          weatherExpectation: XCTestExpectation? = nil,
                          errorExpectation: XCTestExpectation? = nil) -> LocationWeatherViewModel {
        let fakeDatabase = FakeDatabase(addExpectation: addExpectation, removeExpectation: removeExpectation)
        let fakeProvider = FakeProvider()
        let fakeDelegate = FakeWeatherRepositoryDelegate(weatherExpectation: weatherExpectation, errorExpectation: errorExpectation)
        return LocationWeatherViewModel(db: fakeDatabase, provider: fakeProvider, delegate: fakeDelegate)
    }

    struct FakeDatabase: WeatherDatabase {

        let addExpectation: XCTestExpectation?
        let removeExpectation: XCTestExpectation?

        func loadLocations() -> [Location] {
            return [fakeLocation]
        }

        func addLocation(_ location: Location) {
            XCTAssertEqual(location, fakeLocation)
            addExpectation?.fulfill()
        }

        func removeLocation(_ location: Location) {
            XCTAssertEqual(location, fakeLocation)
            removeExpectation?.fulfill()
        }

        func clearDB() { }

    }

    struct FakeProvider: WeatherProvider {

        func searchLocations(query: String?, completionBlock: @escaping (Location?, Error?) -> ()) {
            if query != nil {
                completionBlock(fakeLocation, nil)
            }
            else {
                completionBlock(nil, NSError(domain: "", code: 0))
            }
        }

        func weather(location: Location, completionBlock: @escaping (Weather?, Error?) -> ()) {
            if location.woeId == 0 {
                completionBlock(fakeWeather, nil)
            }
            else {
                completionBlock(nil, NSError(domain: "", code: 0))
            }
        }
    }
    
    struct FakeWeatherRepositoryDelegate: LocationWeatherViewModelDelegate {

        let weatherExpectation: XCTestExpectation?
        let errorExpectation: XCTestExpectation?
        
        func onWeatherStateChanged(state: [LocationWeatherData]) {
            if state.count > 0,
               let first = state.first,
               let weather = first.weather {
                XCTAssertEqual(first.location.woeId, fakeLocation.woeId)
                XCTAssertEqual(weather, fakeWeather)
                weatherExpectation?.fulfill()
            }
        }
        
        func onError(errorDescription: String) {
            #if os(Android)
            XCTAssertEqual(errorDescription, "The operation could not be completed. ( error 0.)")
            #else
            XCTAssertEqual(errorDescription, "The operation couldn’t be completed. ( error 0.)")
            #endif
            errorExpectation?.fulfill()
        }
    }

}
