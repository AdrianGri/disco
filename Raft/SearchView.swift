import SwiftUI

struct SearchView: View {
  @EnvironmentObject var appState: AppState
  @Binding var manualDomain: String
  @State private var isKeyboardVisible = false
  @FocusState private var isTextFieldFocused: Bool

  var body: some View {
    ZStack {
      // Background that fills the entire screen
      Color.appBackground
        .ignoresSafeArea(.all)
        .contentShape(Rectangle())
        .onTapGesture {
          UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

      VStack(spacing: 20) {
        if !isKeyboardVisible {
          Image("LogoTransparent")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 150, height: 150)
            .transition(.opacity)
        }

        Text("Start saving money\nat your favorite\nstores!")
          .font(.custom("Avenir", size: 32))
          .fontWeight(.heavy)
          .foregroundColor(.black)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)

        Text("Paste a URL website **below** and let disco find you discounts")
          .font(.custom("Avenir", size: 12))
          .foregroundColor(.black)
          .frame(maxWidth: .infinity, alignment: .center)

        TextField("e.g. amazon.com", text: $manualDomain)
          .textFieldStyle(PlainTextFieldStyle())
          .focused($isTextFieldFocused)
          .padding()
          .frame(maxWidth: .infinity)
          .background(.textFieldBackground)
          .clipShape(Capsule())
          .autocapitalization(.none)
          .keyboardType(.URL)
          .onTapGesture {
            isTextFieldFocused = true
          }

        Button(action: {
          appState.domainFromDeepLink = manualDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        }) {
          HStack {
            Image(systemName: "magnifyingglass")
            Text("Search for Discounts")
          }
          .foregroundColor(.appAccent)
          .padding()
          .frame(maxWidth: 250)
          .background(.appPrimary)
          .cornerRadius(10)
          .fontWeight(.semibold)
        }
        .padding(.horizontal)

        HStack {
          Text("Try:")
            .foregroundColor(.gray)

          Button("nike.com") { manualDomain = "nike.com" }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(.textFieldBackground)
            .clipShape(Capsule())
            .foregroundColor(.black)
          Button("sephora.com") { manualDomain = "sephora.com" }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(.textFieldBackground)
            .clipShape(Capsule())
            .foregroundColor(.black)
          Button("zara.com") { manualDomain = "zara.com" }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(.textFieldBackground)
            .clipShape(Capsule())
            .foregroundColor(.black)
        }
        .font(.custom("Avenir", size: 14))

        if !isKeyboardVisible {
          VStack(alignment: .leading) {
            Text("How it Works:")
              .fontWeight(.semibold)
              .foregroundColor(.black)
              .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
              Text("1")
                .fontWeight(.bold)
                .padding(15)
                .background(.appPrimary)
                .clipShape(Circle())
                .foregroundColor(.appAccent)
              Text("Enter a website you want to shop at")
            }
            HStack {
              Text("2")
                .fontWeight(.bold)
                .padding(15)
                .background(.appPrimary)
                .clipShape(Circle())
                .foregroundColor(.appAccent)
              Text("Let Disco search for best deals")
            }
            HStack {
              Text("3")
                .fontWeight(.bold)
                .padding(15)
                .background(.appPrimary)
                .clipShape(Circle())
                .foregroundColor(.appAccent)
              Text("Never pay full price again!")
            }
          }
        }
      }
      .padding(.horizontal)
    }
    .onAppear {
      setupKeyboardObservers()
    }
    .onDisappear {
      removeKeyboardObservers()
    }
    .animation(.easeInOut(duration: 0.3), value: isKeyboardVisible)
  }

  private func setupKeyboardObservers() {
    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillShowNotification,
      object: nil,
      queue: .main
    ) { _ in
      isKeyboardVisible = true
    }

    NotificationCenter.default.addObserver(
      forName: UIResponder.keyboardWillHideNotification,
      object: nil,
      queue: .main
    ) { _ in
      isKeyboardVisible = false
    }
  }

  private func removeKeyboardObservers() {
    NotificationCenter.default.removeObserver(
      self, name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.removeObserver(
      self, name: UIResponder.keyboardWillHideNotification, object: nil)
  }
}

#Preview {
  SearchView(manualDomain: .constant(""))
    .environmentObject(AppState())
}
