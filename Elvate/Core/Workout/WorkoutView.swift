//
//  WorkoutView.swift
//  Elvate
//
//  Created by Kamil Jakut on 25/11/2025.
//

import SwiftUI

struct WorkoutView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Twój trening")
                    .font(.largeTitle.bold())
                
                NavigationLink {
                    ExercisesView()
                } label: {
                    Text("Zobacz ćwiczenia")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Workout")
        }
    }
}

#Preview {
    WorkoutView()
}
