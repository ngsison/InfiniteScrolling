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
    @State private var nextBigColorIndex: Int?
    
    var body: some View {
        GeometryReader { geometry in
            
            let numberOfOnScreenScolors: CGFloat = 7
            let numberOfOffScreenColors: CGFloat = 6
            let numberOfBlocks: CGFloat = numberOfOnScreenScolors + 2
            
            let screenWidth = geometry.size.width
            let colorWidthNormal: CGFloat = screenWidth / numberOfBlocks
            let colorWidthSelected: CGFloat = colorWidthNormal * 3
            
            let allColorsWidth: CGFloat = screenWidth + (numberOfOffScreenColors * colorWidthNormal)
            let numberOfColorsForEachSide: CGFloat = 6
            let defaultOffset = -(colorWidthNormal * numberOfColorsForEachSide / 2)
            
            VStack {
                // small colors
                HStack(spacing: 0) {
                    ForEach(getLeftIndices(baseIndex: selectedColorIndex, count: Int(numberOfColorsForEachSide)), id: \.self) { index in
                        SmallColorView(color: colors[index], width: index == nextBigColorIndex ? colorWidthSelected : colorWidthNormal)
                            .onTapGesture {
                                nextColorIndex = index
                            }
                    }
                    
                    SmallColorView(color: colors[selectedColorIndex], width: nextBigColorIndex == nil ? colorWidthSelected : colorWidthNormal)
                    
                    ForEach(getRightIndices(baseIndex: selectedColorIndex, count: Int(numberOfColorsForEachSide)), id: \.self) { index in
                        SmallColorView(color: colors[index], width: index == nextBigColorIndex ? colorWidthSelected : colorWidthNormal)
                            .onTapGesture {
                                nextColorIndex = index
                            }
                    }
                }
                .offset(x: smallColorsOffset)
                
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
            .frame(width: allColorsWidth)
            .offset(x: defaultOffset)
            .gesture(
                DragGesture()
                    .onEnded { gesture in
                        handleDragEnded(gesture: gesture)
                    }
            )
            .onChange(of: nextColorIndex) {
                handleNextColorChanged(using: geometry, colorWidth: colorWidthNormal)
            }
        }
    }
    
    private func getLeftIndices(baseIndex: Int, count: Int) -> [Int] {
        (1...count)
            .reversed()
            .map { index in
                (colors.count + baseIndex - index) % colors.count
            }
    }
    
    private func getRightIndices(baseIndex: Int, count: Int) -> [Int] {
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
    
    private func handleNextColorChanged(using geometry: GeometryProxy, colorWidth: CGFloat) {
        guard let nextColorIndexCopy = nextColorIndex else { return }
        
        handleChangesToSmallColors(using: geometry, colorWidth: colorWidth)
        handleChangesToFullColors(using: geometry)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            // update the data and reset to normal positon without animation

            selectedColorIndex = nextColorIndexCopy
            selectedColorOffset = 0
            
            nextColorOffset = 0
            nextColorIndex = nil
            
            smallColorsOffset = 0
            nextBigColorIndex = nil
        }
    }
    
    private func handleChangesToSmallColors(using geometry: GeometryProxy, colorWidth: CGFloat) {
        guard let nextColorIndex else { return }
        
        let (nextColorWillStartFromLeft, distance) = isNextColorComingFromLeft(fromIndex: selectedColorIndex, toIndex: nextColorIndex)
        
        let baseOffset = smallColorsOffset
        let offsetAdjustment = CGFloat(distance) * colorWidth
        
        withAnimation(.linear(duration: 0.35)) {
            nextBigColorIndex = nextColorIndex
            if nextColorWillStartFromLeft {
                smallColorsOffset = baseOffset + offsetAdjustment
            } else {
                smallColorsOffset = baseOffset - offsetAdjustment
            }
        }
    }
    
    private func handleChangesToFullColors(using geometry: GeometryProxy) {
        guard let nextColorIndex else { return }
        
        let (nextColorWillStartFromLeft, _) = isNextColorComingFromLeft(fromIndex: selectedColorIndex, toIndex: nextColorIndex)
        
        // MARK: Set initial positions without animation
        
        // next color will start from left or right (off screen)
        nextColorOffset = nextColorWillStartFromLeft
        ? -geometry.size.width // left
        : geometry.size.width // right
        
        // selected color will start from center (on screen)
        selectedColorOffset = 0
        
        // MARK: Set target positions with animation
        
        withAnimation(.linear(duration: 0.35)) {
            // next color will move to center (on screen)
            nextColorOffset = 0
            
            // selected color will move to left or right (off screen)
            selectedColorOffset = nextColorWillStartFromLeft
            ? geometry.size.width // right
            : -geometry.size.width // left
        }
    }
    
    private func isNextColorComingFromLeft(fromIndex: Int, toIndex: Int) -> (Bool, Int) {
        let lastIndex = colors.count - 1
        
        // Check if transitioning from the first three positions to somewhere in the last three positions
        if fromIndex >= 0,
           fromIndex <= 2,
           toIndex >= lastIndex - 2,
           toIndex <= lastIndex {
            
            let distanceFromStartToEnd = fromIndex
            let distanceToEndFromCurrent = lastIndex - toIndex
            let distance = distanceFromStartToEnd + distanceToEndFromCurrent + 1
            return (true, distance)
        }
        
        // Check if transitioning from the last three positions to somewhere in the first three positions
        if fromIndex >= lastIndex - 2,
           fromIndex <= lastIndex,
           toIndex >= 0,
           toIndex <= 2 {
            
            let distanceFromEndToStart = lastIndex - fromIndex
            let distanceToStartFromCurrent = toIndex
            let distance = distanceFromEndToStart + distanceToStartFromCurrent + 1
            return (false, distance)
        }
        
        // Handle the normal transition in the middle
        let isComingFromLeft = toIndex < fromIndex
        let distance = abs(fromIndex.distance(to: toIndex))
        return (isComingFromLeft, distance)
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
