//
//  ContentView.swift
//  InfiniteScrolling
//
//  Created by Nathaniel Brion Sison on 2/2/24.
//

import SwiftUI

struct ContentView: View {
    
    private let colors: [String] = [
        "#FF0000",   // Red
        "#00FF00",   // Green
        "#0000FF",   // Blue
        "#FFFF00",   // Yellow
        "#FF00FF",   // Magenta
        "#00FFFF",   // Cyan
        "#FF8000",   // Orange
        "#0080FF",   // Light Blue
        "#8000FF",   // Purple
        "#FF0080",   // Pink
        "#80FF00",   // Lime Green
        "#0080FF",   // Light Blue
        "#00FF80",   // Sea Green
        "#8000FF",   // Purple
        "#FF8000",   // Orange
        "#FF0080",   // Pink
        "#0080FF",   // Light Blue
        "#80FF00",   // Lime Green
        "#00FF80",   // Sea Green
        "#008080"    // Teal
    ]
    
    @State private var selectedColorIndex: Int = 0
    @State private var selectedColorOffset: CGFloat = 0
    
    @State private var nextColorIndex: Int?
    @State private var nextColorOffset: CGFloat = 0
    
    @State private var smallColorsOffset: CGFloat = 0
    
    @State private var nextSmallColorIndex: Int?
    @State private var nextSmallColorOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // small colors
                ZStack {
                    let numberOfColors: CGFloat = 7
                    let numberOfBlocks: CGFloat = numberOfColors + 2
                    
                    let unselectedColorWidth: CGFloat = geometry.size.width / numberOfBlocks
                    let selectedColorWidth: CGFloat = unselectedColorWidth * 3
                    
                    if let nextSmallColorIndex {
                        SmallColorView(color: colors[nextSmallColorIndex], width: unselectedColorWidth)
                            .offset(x: nextColorOffset)
                    }
                    
                    HStack(spacing: 0) {
                        ForEach(getLeftIndices(baseIndex: selectedColorIndex), id: \.self) { index in
                            SmallColorView(color: colors[index], width: unselectedColorWidth)
                        }
                        
                        SmallColorView(color: colors[selectedColorIndex], width: selectedColorWidth)
                        
                        ForEach(getRightIndices(baseIndex: selectedColorIndex), id: \.self) { index in
                            SmallColorView(color: colors[index], width: unselectedColorWidth)
                        }
                    }
                }
                
                // full colors
                ZStack {
                    if let nextColorIndex {
                        Color(hex: colors[nextColorIndex])
                            .offset(x: nextColorOffset)
                    }
                    
                    Color(hex: colors[selectedColorIndex])
                        .offset(x: selectedColorOffset)
                }
                .frame(width: geometry.size.width)
            }
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        handleDragEnded(gesture: gesture)
                    }
            )
            .onChange(of: nextColorIndex) {
                handleNextColorChanged(using: geometry)
            }
        }
    }
    
    private func getLeftIndices(baseIndex: Int, count: Int = 3) -> [Int] {
        (1...count)
            .reversed()
            .map { index in
                (colors.count + baseIndex - index) % colors.count
            }
    }
    
    private func getRightIndices(baseIndex: Int, count: Int = 3) -> [Int] {
        (1...count)
            .map { index in
                (colors.count + baseIndex + index) % colors.count
            }
    }
    
    private func handleDragEnded(gesture: DragGesture.Value) {
        let dragAmount = gesture.translation.width
        if dragAmount < 0 {
            nextColorIndex = (colors.count + selectedColorIndex + 1) % colors.count
        } else if dragAmount > 0 {
            nextColorIndex = (colors.count + selectedColorIndex - 1) % colors.count
        }
    }
    
    private func handleNextColorChanged(using geometry: GeometryProxy) {
        guard let nextColorIndex else { return }
        
        handleChangesToSmallColors(using: geometry)
        handleChangesToFullColors(using: geometry)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            // update the data and reset to normal positon without animation
            selectedColorIndex = nextColorIndex
            selectedColorOffset = 0
            
            self.nextColorIndex = nil
            self.nextSmallColorIndex = nil
        }
    }
    
    private func handleChangesToSmallColors(using geometry: GeometryProxy) {
        guard let nextColorIndex else { return }
        
        // get the -3 or +3 index relative to nextColorIndex index -- is this even correct?
        // don't forget big steps (tap on small colors)
        
    }
    
    private func handleChangesToFullColors(using geometry: GeometryProxy) {
        guard let nextColorIndex else { return }
        
        var nextColorWillStartFromLeft: Bool
        
        if selectedColorIndex == 0, nextColorIndex == colors.count - 1 {
            // Transitioning from start to end
            nextColorWillStartFromLeft = true
        } else if selectedColorIndex == colors.count - 1, nextColorIndex == 0 {
            // Transitioning from end to start
            nextColorWillStartFromLeft = false
        } else {
            // Transitioning in the middle (normal transition)
            nextColorWillStartFromLeft = nextColorIndex < selectedColorIndex
        }
        
        // next color will start from left or right
        nextColorOffset = nextColorWillStartFromLeft
        ? -geometry.size.width // left
        : geometry.size.width // right
        
        // selected color will start from center
        selectedColorOffset = 0
        
        withAnimation(.linear(duration: 0.35)) {
            // next color will move to center
            nextColorOffset = 0
            
            // selected color will move to left or right
            selectedColorOffset = nextColorWillStartFromLeft
            ? geometry.size.width // right
            : -geometry.size.width // left
        }
    }
}

struct SmallColorView: View {
    let color: String
    let width: CGFloat
    
    var body: some View {
        Color(hex: color)
            .clipShape(Circle())
            .padding(4)
            .frame(width: width, height: width)
    }
}

#Preview {
    ContentView()
}
