//
//  SettingSidebarView.swift
//  Dietelligence
//
//  Custom left-sliding sidebar for settings with layered detail view
//

import SwiftUI

enum SettingDetailPage {
    case profile
    case apiSetting
}

struct SettingSidebarView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @State private var selectedPage: SettingDetailPage?
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let sidebarWidth = screenWidth * 0.85

            ZStack(alignment: .leading) {
                // Layer 1: Detail View (covers entire screen when shown)
                if let page = selectedPage {
                    Group {
                        switch page {
                        case .profile:
                            InfoView(
                                initialName: UserProfileManager.shared.getProfile().name,
                                onFinished: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedPage = nil
                                    }
                                },
                                showResetButton: true
                            )
                        case .apiSetting:
                            APISettingView(onDismiss: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedPage = nil
                                }
                            })
                            .environmentObject(appState)
                        }
                    }
                    .frame(width: screenWidth, height: geometry.size.height)
                    .offset(x: detailViewOffset(
                        hasDetailView: true,
                        screenWidth: screenWidth
                    ))
                    .transition(.move(edge: .trailing))
                }

                // Layer 2: Sidebar (Settings List)
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    Text("Settings")
                        .font(.system(.title, design: .serif, weight: .bold))
                        .foregroundStyle(.mainText)
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                        .padding(.bottom, 20)

                    // Settings list
                    SettingsListContent(selectedPage: $selectedPage)
                }
                .frame(width: sidebarWidth, height: geometry.size.height)
                .background(Color.backGround)
                .offset(x: sidebarOffset(
                    isPresented: isPresented,
                    hasDetailView: selectedPage != nil,
                    screenWidth: screenWidth,
                    sidebarWidth: sidebarWidth,
                    dragOffset: dragOffset
                ))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only allow dragging to the right when no detail view
                            if selectedPage == nil && value.translation.width > 0 {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if selectedPage == nil {
                                // Dismiss sidebar if dragged more than 30% of width
                                if value.translation.width > sidebarWidth * 0.3 {
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
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedPage != nil)
            .animation(.spring(response: 0.3), value: dragOffset)
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    // Reset states when opening
                    dragOffset = 0
                    selectedPage = nil
                } else {
                    // Close detail view when closing sidebar
                    selectedPage = nil
                }
            }
        }
        .ignoresSafeArea()
    }

    // Calculate detail view offset (从右边滑入，覆盖整个屏幕)
    private func detailViewOffset(hasDetailView: Bool, screenWidth: CGFloat) -> CGFloat {
        if hasDetailView {
            return 0  // 完全可见
        } else {
            return screenWidth  // 隐藏在右边屏幕外
        }
    }

    // Calculate sidebar offset (从右边滑入到屏幕右侧)
    private func sidebarOffset(
        isPresented: Bool,
        hasDetailView: Bool,
        screenWidth: CGFloat,
        sidebarWidth: CGFloat,
        dragOffset: CGFloat
    ) -> CGFloat {
        if !isPresented {
            // Sidebar完全隐藏在右边屏幕外
            return screenWidth
        } else if hasDetailView {
            // 详情页显示时，sidebar移到左边屏幕外
            return -sidebarWidth
        } else {
            // Sidebar可见，停靠在屏幕右侧
            // 从左边缘开始计算：需要偏移 (screenWidth - sidebarWidth) 才能靠右
            return screenWidth - sidebarWidth + dragOffset
        }
    }
}

// MARK: - Settings List Content

struct SettingsListContent: View {
    @Binding var selectedPage: SettingDetailPage?

    var body: some View {
        List {
            // Profile
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedPage = .profile
                }
            } label: {
                HStack {
                    Image(systemName: "person.fill")
                    Text("Profile")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.backGround)

            // AI Settings
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedPage = .apiSetting
                }
            } label: {
                HStack {
                    Image(systemName: "sparkle")
                    Text("AI Settings")
                    Spacer()

                    // Show status indicator
                    if GeminiConfiguration.hasAPIKey {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .imageScale(.small)
                    } else {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .imageScale(.small)
                    }

                    Image(systemName: "chevron.right")
                        .imageScale(.small)
                        .padding(.leading, 4)
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(Color.backGround)
            
        }
        .listStyle(.plain)
        .font(.title2)
        .fontDesign(.serif)
        .fontWeight(.bold)
        .foregroundStyle(.mainText)
    }
}

#Preview {
    SettingSidebarView(isPresented: .constant(true))
}
