//
//  BlockView_render.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 23/2/26.
//

import SwiftUI

struct BlockView: View {
    
    let block: ContentBlock
    let fontSize: CGFloat //Tamaño de Fuente
    let fontColor: UIColor //Color de Fuente
    
    var body: some View {
        render(block.content)
    }
    
    @ViewBuilder
    private func render(_ content: BlockType) -> some View {
        
        switch content {
             
        case .text(let string):
            SelectableTextShareView(getContent: string, fontSizeContenido: self.fontSize, textContentdColor: self.fontColor)
            //Text(string)
            
        case .markdown(let string):
            Text(.init(string))
            
        case .attributed(let attributed):
            Text(attributed)
            
        case .imageLocal(let name, let size):
            Image(name)
                .resizable()
                .scaledToFit()
                .cornerRadius(12)
                .frame(width: size, height: size)
            
        case .imageRemote(let url, let size):
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .frame(width: size, height: size)
                case .failure:
                    Image(systemName: "photo")      
                @unknown default:
                    EmptyView()
                }
            }
            
        case .link(let title, let url):
            Link(title, destination: url)
            
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top) {
                        Text("•")
                        Text(item)
                    }
                }
            }
            
        case .quote(let text):
            HStack(alignment: .top) {
                Rectangle()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 4)
                Text(text)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            
        case .code(let code):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
        case .divider:
            Divider()
            
            
        case .bibliography(let title, let entries):
            
            VStack(alignment: .leading, spacing: 16) {
                
                if let title {
                    Text(title)
                        .font(.headline)
                }
                
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    
                    VStack(alignment: .leading, spacing: 6) {
                        
                        HStack(alignment: .top, spacing: 6) {
                            
                            if let url = entry.url {
                                Link("[\(index + 1)]", destination: url)
                                    .font(.footnote)
                                    .foregroundStyle(Color.primary)
                                    .bold()
                            }else{
                                Text("[\(index + 1)]")
                                    .fontWeight(.semibold)
                            }
                            
                            
                            Text(entry.text)
                                .font(.system(size: fontSize - 2))
                                .foregroundColor(Color(fontColor))
                        }
                        
                        
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
        case .relacionado(let title, let items):
            
            VStack(alignment: .leading, spacing: 12) {
                
                if let title = title {
                    Text(title)
                        .font(.body)
                }
                
                ForEach(items) { item in
                    
                    NavigationLink(destination: RelatedFileDetailView(fileName: item.fileName)) {
                        Text("🔸\(item.displayName)")
                            .foregroundColor(Color.primary)
                            .bold()
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            
        }
        
        
    }
    
}
