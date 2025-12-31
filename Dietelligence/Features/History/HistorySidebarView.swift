//
//  HistorySidebarView.swift
//  Dietelligence
//
//  Custom left-sliding sidebar with layered detail view (ZStack approach)
//

import SwiftUI

struct HistorySidebarView: View {
    @Binding var isPresented: Bool
    @State private var selectedMeal: MealEntity?
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let sidebarWidth = screenWidth * 0.85

            ZStack(alignment: .leading) {
                // Layer 1: Detail View (leftmost)
                if let meal = selectedMeal {
                    HistoryDishListView(
                        meal: meal,
                        onDismiss: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedMeal = nil
                            }
                        }
                    )
                    .frame(width: screenWidth, height: geometry.size.height)
                    .offset(x: detailViewOffset(
                        hasDetailView: true,
                        screenWidth: screenWidth
                    ))
                    .transition(.move(edge: .leading))
                }

                // Layer 2: Sidebar
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    Text("Meal History")
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundStyle(.mainText)
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 20)

                    // History list
                    HistoryList(selectedMeal: $selectedMeal)
                }
                .frame(width: sidebarWidth, height: geometry.size.height)
                .background(Color.backGround)
                .offset(x: sidebarOffset(
                    isPresented: isPresented,
                    hasDetailView: selectedMeal != nil,
                    screenWidth: screenWidth,
                    sidebarWidth: sidebarWidth,
                    dragOffset: dragOffset
                ))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow dragging to the left when no detail view
                            if selectedMeal == nil && value.translation.width < 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if selectedMeal == nil {
                                // Dismiss sidebar if dragged more than 30% of width
                                if -value.translation.width > sidebarWidth * 0.3 {
                                    withAnimation(.spring(response: 0.3)) {
                                        isPresented = false
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                        }
                )
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isPresented)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedMeal != nil)
            .animation(.spring(response: 0.3), value: dragOffset)
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    // Reset states when opening
                    dragOffset = 0
                    selectedMeal = nil
                } else {
                    // Close detail view when closing sidebar
                    selectedMeal = nil
                }
            }
        }
        .ignoresSafeArea()
    }

    // Calculate detail view offset
    private func detailViewOffset(hasDetailView: Bool, screenWidth: CGFloat) -> CGFloat {
        if hasDetailView {
            return 0  // Visible at full screen
        } else {
            return -screenWidth  // Hidden to the left
        }
    }

    // Calculate sidebar offset
    private func sidebarOffset(
        isPresented: Bool,
        hasDetailView: Bool,
        screenWidth: CGFloat,
        sidebarWidth: CGFloat,
        dragOffset: CGFloat
    ) -> CGFloat {
        if !isPresented {
            // Sidebar completely hidden to the left
            return -sidebarWidth
        } else if hasDetailView {
            // Sidebar moves completely to the right (off-screen)
            return screenWidth
        } else {
            // Sidebar visible at the left with drag offset
            return dragOffset
        }
    }
}

#Preview {
    HistorySidebarView(isPresented: .constant(true))
}
