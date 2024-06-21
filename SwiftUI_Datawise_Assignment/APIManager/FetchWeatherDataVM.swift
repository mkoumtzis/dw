//
//  FetchWeatherData.swift
//  SwiftUI_Datawise_Assignment
//
//  Created by Angelos Staboulis on 18/6/24.
//

import Alamofire
import Foundation

enum EndPoint: String {
  case hourly = "/hourly"
  case daily = "/daily"
}

actor FetchWeatherData {
//    func fetchWeatherDataHourly(endpoint:String,completion:@escaping ([Model])->()){
//        guard let baseURL = URL(string:"https://test.dev.datawise.ai/") else{
//            return
//        }
//        guard let request = RequestBuilder(path: endpoint)
//            .makeRequest(baseURL: baseURL) else{
//            return
//        }
//        AF.request(request).response { dataResponse in
//            switch (dataResponse.result){
//            case .success(_):
//                do{
//                    let decode = try JSONDecoder().decode([Model].self, from: dataResponse.data!)
//                    completion(decode)
//                }
//                catch{
//                    debugPrint((error.localizedDescription))
//                }
//            case .failure(let error):
//                debugPrint("something went wrong=",error.localizedDescription)
//
//            }
//        }
//    }
  
  private let baseURL = "https://test.dev.datawise.ai/"

  func fetchWeatherData(endpoint: EndPoint) async throws -> [Model] {
    guard let baseURL = URL(string: baseURL) else {
      throw URLError(.badURL)
    }

    guard let request = RequestBuilder(path: endpoint.rawValue).makeRequest(baseURL: baseURL) else {
      throw URLError(.badURL)
    }

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(request).response { dataResponse in
        switch dataResponse.result {
        case .success:
          do {
            let decodedData = try JSONDecoder().decode([Model].self, from: dataResponse.data!)
            continuation.resume(returning: decodedData)
          } catch {
            continuation.resume(throwing: error)
          }
        case let .failure(error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}

// actor FetchWeatherDataDaily {
//  func fetchWeatherDataDaily(endpoint: String, completion: @escaping ([Model]) -> Void) {
//    guard let baseURL = URL(string: "https://test.dev.datawise.ai/") else {
//      return
//    }
//    guard let request = RequestBuilder(path: endpoint)
//      .makeRequest(baseURL: baseURL)
//    else {
//      return
//    }
//    AF.request(request).response { dataResponse in
//      switch dataResponse.result {
//      case .success:
//        do {
//          let decode = try JSONDecoder().decode([Model].self, from: dataResponse.data!)
//          completion(decode)
//        } catch {
//          debugPrint(error.localizedDescription)
//        }
//      case let .failure(error):
//        debugPrint("something went wrong=", error.localizedDescription)
//      }
//    }
//  }
//
//  func fetchWeatherDataDaily(endpoint: String) async throws -> [Model] {
//    guard let baseURL = URL(string: "https://test.dev.datawise.ai/") else {
//      throw URLError(.badURL)
//    }
//
//    guard let request = RequestBuilder(path: endpoint).makeRequest(baseURL: baseURL) else {
//      throw URLError(.badURL)
//    }
//
//    return try await withCheckedThrowingContinuation { continuation in
//      AF.request(request).response { dataResponse in
//        switch dataResponse.result {
//        case .success:
//          do {
//            let decodedData = try JSONDecoder().decode([Model].self, from: dataResponse.data!)
//            continuation.resume(returning: decodedData)
//          } catch {
//            continuation.resume(throwing: error)
//          }
//        case let .failure(error):
//          continuation.resume(throwing: error)
//        }
//      }
//    }
//  }
// }

@MainActor
class FetchWeatherDataVM: ObservableObject {
//  let daily = FetchWeatherDataDaily()
  let weatherData = FetchWeatherData()

  @Published var models: [Model] = []

  @Published var currentWeather: CurrentDayWeather?
  @Published var weatherDailyArray: [WeatherDay] = []
  @Published var weatherHourlyArray: [CurrentDayWeather] = []
//    func fetchWeatherDataDaily(endpoint:String,completion:@escaping ([Model])->()){
//        Task{
//            await daily.fetchWeatherDataDaily(endpoint: endpoint) { array in
//                completion(array)
//            }
//        }
//    }

//    func fetchWeatherDataHourly(endpoint:String,completion:@escaping ([Model])->()){
//        Task{
//            await hourly.fetchWeatherDataHourly(endpoint: endpoint) { array in
//                completion(array)
//            }
//        }
//    }

  func fetchWeather() {
    Task {
      do {
        let arrayHourly = try await weatherData.fetchWeatherData(endpoint: .hourly)
        let arrayDaily = try await weatherData.fetchWeatherData(endpoint: .daily)

        for item in arrayHourly {
          weatherHourlyArray.append(CurrentDayWeather(time: Helper.shared.convertISOTime(date: item.date), dayOfWeek: Helper.shared.convertISODateFullDate(date: item.date), imageName: Helper.shared.createIcon(condition: item.condition), condition: item.condition, temperature: item.temperature))
        }
        guard let fetchCurrentDayWeather = arrayHourly.first else {
          return
        }
        currentWeather = CurrentDayWeather(time: Helper.shared.convertISOTime(date: fetchCurrentDayWeather.date), dayOfWeek: Helper.shared.convertISODateFullDate(date: fetchCurrentDayWeather.date), imageName: Helper.shared.createIcon(condition: fetchCurrentDayWeather.condition), condition: fetchCurrentDayWeather.condition, temperature: fetchCurrentDayWeather.temperature)

        for item in arrayDaily {
          weatherDailyArray.append(WeatherDay(dayOfWeek: Helper.shared.convertISODate(date: item.date), imageName: Helper.shared.createIcon(condition: item.condition), condition: item.condition, temperature: item.temperature))
        }
        
      } catch {}
    }
  }
}
