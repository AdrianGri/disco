import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @Binding var manualDomain: String

    var body: some View {
        VStack(spacing: 20) {
            Image("LogoTransparent")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
            
            Text("Start saving money\nat your favorite\nstores!")
                .font(.custom("Avenir", size: 32))
                .fontWeight(.heavy)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Paste a URL website **below** and let disco find you discounts")
                .font(.custom("Avenir", size: 12))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)
            
            TextField("e.g. amazon.com", text: $manualDomain)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .frame(maxWidth: .infinity)
                .background(.textFieldBackground)
                .clipShape(Capsule())
                .autocapitalization(.none)
                .keyboardType(.URL)
            
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
        .padding(.horizontal)
    }
}

#Preview {
    SearchView(manualDomain: .constant(""))
        .environmentObject(AppState())
}
