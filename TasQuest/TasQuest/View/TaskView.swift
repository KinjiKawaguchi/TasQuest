//
//  TaskView.swift
//  TasQuest
//
//  Created by KinjiKawaguchi on 2023/09/04.
//


import SwiftUI

struct TaskView: View {
    @State var statusIndex: Int
    @State var goalIndex: Int
    
    @Binding var goalIsStarred: Bool
    
    @State private var reloadFlag = false  // 追加
    
    @State private var showingUnityView = false  // Unityビュー表示フラグ

    @State var showingManageTaskModal = false  // ハーフモーダルの表示状態を管理
    
    
    var body: some View {
        let goal: Goal = AppDataSingleton.shared.appData.statuses[statusIndex].goals[goalIndex]
        
        ZStack {
            let taskCount = goal.tasks.filter { $0.isVisible }.count
            
            let height = max(0, (87.95) * CGFloat(taskCount - 1))
            VStack {
                HeaderView(statusIndex: statusIndex, goalIndex: goalIndex,goalIsStarred: $goalIsStarred)
                
                Rectangle()
                    .fill(Color.gray)  // 色を設定
                    .frame(height: 2)  // 厚みを設定
                
                ScrollView {
                    ZStack(alignment: .leading) {
                        VStack {
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 5, height: height)
                        }
                        .padding(.leading, 9)
                        
                        
                        ScrollView{
                            TaskListView(statusIndex: statusIndex, goalIndex: goalIndex)
                        }
                    }
                }
                Button(action: {
                    showingManageTaskModal.toggle()  // ハーフモーダルを表示
                }) {
                    HStack{
                        Spacer()
                        Text("+ タスクを追加")
                            .frame(height: 55)
                            .font(.callout)
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        Spacer()
                    }
                    .background(Color.gray.opacity(0.4))  // オパシティを0.4に設定
                    .cornerRadius(8)
                    .sheet(isPresented: $showingManageTaskModal) {
                        ManageTaskView(statusIndex: statusIndex, goalIndex: goalIndex)  // ハーフモーダルの内容
                    }
                }
                .padding(.top, 8)
                
                NavigationLink("", destination: UnityHostingController(), isActive: $showingUnityView).hidden()
            }
            .padding()
            
        }
        
        // 画面下部のボタンエリア
        HStack {
            // ゲームコントローラーのボタン
            Button(action: {
                showingUnityView.toggle()
            }) {
                HStack{
                    Spacer()
                    Image(systemName: "gamecontroller")
                    Text("ゲームビュー")
                    Spacer()
                }
                .frame(width: 180, height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            // ゴミ箱へのボタン
            Button(action: {
                // Trash action here
            }) {
                HStack{
                    Spacer()
                    Image(systemName: "trash")
                    Text("ゴミ箱")
                    Spacer()
                }
                .frame(width: 180, height: 50)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.bottom, 16)
        .id(reloadFlag)  // 追加
        .onReceive(
            NotificationCenter.default.publisher(for: Notification.Name("TaskUpdated")),
            perform: { _ in
                self.reloadFlag.toggle()
            }
        )
        .navigationBarBackButtonHidden(true)
    }
}

struct HeaderView: View {
    @State var statusIndex: Int
    @State var goalIndex: Int
    
    @Binding var goalIsStarred: Bool

    
    @Environment(\.presentationMode) var presentationMode
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    var body: some View {
        var goal = AppDataSingleton.shared.appData.statuses[statusIndex].goals[goalIndex]
        VStack{
            ZStack(alignment: .leading) {
                HStack {
                    Spacer()
                    
                    Text(goal.name)
                        .font(.title)
                        .bold()
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    Button(action: {
                        goal.isStarred.toggle()  // @Bindingを通してgoalの状態を変更
                        goalIsStarred.toggle()
                        TaskViewModel(goal: goal).toggleIsStarred(goalID: goal.id)
                    }) {
                        Image(systemName: goal.isStarred ? "star.fill" : "star")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(goal.isStarred ? .yellow : .gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)

                Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.blue)
                }
                .padding(.leading)
            }
            .padding(.top)
        }
        Text(dateFormatter.string(from: goal.dueDate))
            .font(.subheadline)
            .foregroundColor(.gray)
    }
}

struct TaskListView: View {
    @State var statusIndex: Int
    @State var goalIndex: Int
    
    var body: some View {
        let goal: Goal = AppDataSingleton.shared.appData.statuses[statusIndex].goals[goalIndex]
        ForEach(goal.tasks.indices, id: \.self) { index in
            if goal.tasks[index].isVisible {
                TaskRow(statusIndex: statusIndex, goalIndex: goalIndex, taskIndex: index)
            }
        }
        .onAppear {
            print("Current tasks: \(goal.tasks)")
        }
    }
}

struct TaskRow: View {
    @State var statusIndex: Int
    @State var goalIndex: Int
    @State var taskIndex: Int

    @State private var showTaskDetailPopupView: Bool = false  
    
    
    var body: some View {
        let task: TasQuestTask = AppDataSingleton.shared.appData.statuses[statusIndex].goals[goalIndex].tasks[taskIndex]
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter
        }()
        
        // Calculate the fill color based on the task's current and max health
        var fillColor: Color {
            let percentage = task.currentHealth / task.maxHealth
            if percentage > 0.5 {
                return .green
            } else if percentage > 0.2 {
                return .yellow
            } else {
                return .red
            }
        }
        
        HStack {
            // Circle icon
            Image(systemName: "circle.fill")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
            
            Button(action: {
                self.showTaskDetailPopupView = true  // ポップアップビューを表示
            }) {
                // Task name and tags
                VStack(alignment: .leading) {
                    Text(task.name)
                        .font(.body)
                        .foregroundColor(.black)
                    
                    HStack {
                        ForEach(task.tags.prefix(3).indices, id: \.self) { tagIndex in
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        Color(
                                            red: Double(task.tags[tagIndex].color[0]),
                                            green: Double(task.tags[tagIndex].color[1]),
                                            blue: Double(task.tags[tagIndex].color[2])
                                        ).opacity(0.2)
                                    )
                                let truncatedTag = String(task.tags[tagIndex].name.prefix(5))
                                let displayTag = task.tags[tagIndex].name.count > 5 ? "\(truncatedTag)..." : truncatedTag
                                Text(displayTag)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .fixedSize()
                            .padding(.vertical, 2)
                        }
                    }
                    // 修正された部分
                    Text(dateFormatter.string(from: task.dueDate))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Health bar
                VStack {
                    let percentage: Float = task.maxHealth == 0 ? 0 : task.currentHealth / task.maxHealth
                    
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 150, height: 8)
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(fillColor)
                                .frame(width: 150 * CGFloat(percentage))
                        }
                        .cornerRadius(4)
                    
                    Text("\(Int(task.currentHealth))/\(Int(task.maxHealth))")
                        .font(.footnote.bold())
                        .kerning(2)
                        .padding(.bottom, 24)
                }
            }
        }
        .frame(height: 80)
        .background(Color.clear)
        .onAppear(){
            print("Rendering task with ID: \(task.id)")
            
        }        
        .sheet(isPresented: $showTaskDetailPopupView) {
            TaskDetailPopupView(statusIndex: statusIndex, goalIndex: goalIndex, task: AppDataSingleton.shared.appData.statuses[statusIndex].goals[goalIndex].tasks[taskIndex])  // タスクの詳細ビュー
        }
    }
}

struct TaskDetailPopupView: View {
    @State var statusIndex: Int
    @State var goalIndex: Int
    @State var task: TasQuestTask
    
    @State var showingManageTaskModal = false  // ハーフモーダルの表示状態を管理

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
    
    // Calculate the fill color based on the task's current and max health
    var fillColor: Color {
        let percentage = task.currentHealth / task.maxHealth
        if percentage > 0.5 {
            return .green
        } else if percentage > 0.2 {
            return .yellow
        } else {
            return .red
        }
    }
    
    func displayTag(tag: Tag?) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    tag != nil ?
                    Color(
                        red: Double(tag!.color[0]),
                        green: Double(tag!.color[1]),
                        blue: Double(tag!.color[2])
                    ).opacity(0.2) : Color.clear
                )
            if let actualTag = tag {
                let truncatedTag = String(actualTag.name.prefix(8))
                let displayTag = actualTag.name.count > 8 ? "\(truncatedTag)..." : truncatedTag
                Text(displayTag)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .fixedSize()
        .padding(.vertical, 2)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("タスクの詳細")
                    .font(.headline)
                    .foregroundColor(Color.primary)
                Spacer()
                Button(action: {
                    self.showingManageTaskModal = true
                }){
                    Image(systemName: "pencil")
                        .foregroundColor(Color.blue)
                        .padding(10)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
            }
            .padding()
            
            Divider()
                .background(Color.gray)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("名前: \(task.name)")
                    .fontWeight(.medium)
                
                Text("説明: \(task.description)")
                    .font(.caption)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color.gray)
                    Text("期日: \(task.dueDate, formatter: dateFormatter)")
                }
                
                HStack{
                    Image(systemName: "tag")
                        .foregroundColor(Color.gray)
                    Text("タグ: \(task.tags.map { $0.name }.joined(separator: ", "))")
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color.gray)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(task.tags, id: \.name) { tag in
                                    displayTag(tag: tag)
                                        .padding(4)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.2)))
                                }
                            }
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(Color.gray)
                    Text("作成日時: \(task.createdAt, formatter: dateFormatter)")
                }
                
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(Color.gray)
                    Text("更新日: \(task.updatedAt, formatter: dateFormatter)")
                }
                
                HStack{
                    Spacer()
                    VStack {
                        let percentage: Float = task.maxHealth == 0 ? 0 : task.currentHealth / task.maxHealth
                        
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 300, height: 8)
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(fillColor)
                                    .frame(width: 300 * CGFloat(percentage))
                            }
                            .cornerRadius(4)
                        
                        Text("\(Int(task.currentHealth))/\(Int(task.maxHealth))")
                            .font(.footnote.bold())
                            .kerning(2)
                            .padding(.bottom, 24)
                    }
                    Spacer()
                }
                
            }
            .padding()
            .sheet(isPresented: self.$showingManageTaskModal) {
                ManageTaskView(statusIndex: statusIndex,goalIndex: goalIndex, editingTask: task)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 5)
    }
}
