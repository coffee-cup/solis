//
//  RootView.swift
//  SunriseSunset
//

import SwiftUI

struct RootView: View {
    @Environment(LocationModel.self) private var location
    @Environment(MenuState.self) private var menu
    @Environment(\.scenePhase) private var scenePhase

    @State private var resetToken = 0

    private let menuWidthFraction: CGFloat = 0.7
    private let dimAlpha: CGFloat = 0.4

    var body: some View {
        GeometryReader { geo in
            let menuWidth = geo.size.width * menuWidthFraction

            ZStack(alignment: .leading) {
                TimelineView(resetToken: resetToken)
                    .ignoresSafeArea()

                // Menu button (bottom-left); fades out as the menu comes out.
                menuButton
                    .opacity(1 - menu.fraction)

                // Dim layer over the timeline while the menu is out; tap or
                // drag left to close.
                Color.black
                    .opacity(dimAlpha * menu.fraction)
                    .ignoresSafeArea()
                    .allowsHitTesting(menu.isOut)
                    .onTapGesture {
                        menu.close()
                    }
                    .gesture(closeDrag(menuWidth: menuWidth))

                MenuView()
                    .frame(width: menuWidth)
                    .ignoresSafeArea()
                    .offset(x: (menu.fraction - 1) * menuWidth)
                    .accessibilityHidden(!menu.isOut)

                // Left-edge strip: drag the menu out. Always present — removing
                // it mid-drag would cancel its own gesture — and sits above the
                // timeline, whose pan ignores touches starting at x < 40.
                Color.clear
                    .frame(width: 20)
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .gesture(openDrag(menuWidth: menuWidth))
            }
        }
        .statusBarHidden(true)
        .onAppear {
            location.start()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                resetToken += 1
            }
        }
    }

    private var menuButton: some View {
        VStack {
            Spacer()
            HStack {
                Button {
                    menu.open()
                } label: {
                    Image("menu_button")
                        .padding(7)
                }
                .accessibilityLabel("menu")
                .padding(.leading, 30)
                .padding(.bottom, 30)
                Spacer()
            }
        }
    }

    private func openDrag(menuWidth: CGFloat) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                menu.setDragFraction(value.location.x / menuWidth)
            }
            .onEnded { _ in
                menu.settle()
            }
    }

    private func closeDrag(menuWidth: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                menu.setDragFraction(1 + value.translation.width / menuWidth)
            }
            .onEnded { _ in
                menu.settle()
            }
    }
}
