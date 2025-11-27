//
//  MeasurementsView.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import SwiftUI

struct MeasurementsView: View {
    private let metrics: [MeasurementMetric] = MeasurementMetric.allCases
    
    var body: some View {
        List {
            Section(header: Text("Measurements")) {
                ForEach(metrics) { metric in
                    NavigationLink {
                        MeasurementDetailView(metric: metric)
                    } label: {
                        HStack {
                            Text(metric.title)
                            Spacer()
                            Text(metric.unit)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Measurements")
    }
}

#Preview {
    NavigationStack {
        MeasurementsView()
    }
}
