import Testing
import Foundation
@testable import HavenGPXParser

@Suite("Route and Waypoint Parsing")
struct RouteWaypointTests {

    @Test("Parses routes and standalone waypoints")
    func parseRouteWithWaypoints() throws {
        let url = try fixtureURL("route_with_waypoints")
        let doc = try GPXParser.parse(contentsOf: url)

        #expect(doc.metadata?.name == "Bay Area Tour")
        #expect(doc.metadata?.keywords == "cycling,bay area,scenic")

        // Standalone waypoints
        #expect(doc.waypoints.count == 2)
        #expect(doc.waypoints[0].name == "Golden Gate Bridge")
        #expect(doc.waypoints[0].description == "Start point")
        #expect(doc.waypoints[0].symbol == "Flag")
        #expect(doc.waypoints[1].name == "Sausalito")

        // Route
        #expect(doc.routes.count == 1)
        let route = doc.routes[0]
        #expect(route.name == "Scenic Route")
        #expect(route.description == "A scenic cycling route across the Golden Gate")
        #expect(route.number == 1)
        #expect(route.type == "Cycling")
        #expect(route.points.count == 4)
        #expect(route.points[0].name == "Start")
        #expect(route.points[3].name == "End")
    }
}
