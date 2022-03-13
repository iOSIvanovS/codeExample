import Foundation


// ВНЕШНИЕ МОДЕЛИ ДАННЫХ. В таком виде существуют документы в вэб-системе и файлы на телефоне.

// Документ из вэб-системы. Представляет собой некоторые метаданные.
struct Doc: Codable {
    var id: UUID        // id документа в вэб-системе
    var name: String    // Имя файла
    var ext: String     // Расширение
}

// Файл с данными и метаданными
struct File: Codable {
    var id: UUID        // id файла в памяти устройства
    var doc: Doc        // Метаданные
    var data: Data      // Данные
}


final class FileSystem {
    
    // ВНУТРЕННИЕ МОДЕЛИ ДАННЫХ
    
    // Тип отношения файла к внешней сущности. Настройте на ваше усмотрение, например:
    enum RelationType: Codable {
        case inspectionAppends, // Документ, приложенный к инспекции
             remarkAppends,     // Докумен, приложенный к замечанию
             inspectionPhotos,  // Фото, приложенное к инспекции
             remarkPhotos,      // Фото, приложенное к замечанию
             objectDocs,        // Документ по стройке
             drawings           // Чертеж
    }
    
    // Отношение к внешней сущности
    private struct Relation: Codable {
        var docID: UUID         // id документа в вэб-системе
        var entityID: UUID      // id внешней сущности
        var type: RelationType  // Тип отношения
    }
    
    // Путь к месту хранения файлов приложения. Настройте на ваше усмотрение.
    private static let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // Расширение файлов, с ним они будут храниться в памяти устройства. Настройте на ваше усмотрение.
    private static let ext = "myfile"
    
    
    // API РАЗРАБОТЧИКА
    
    // Получение файла по id документа из вэб-системы
    class func getFile(docID: UUID) -> File? {
        for relation in getAllRelations() {
            if relation.value.contains(where: {$0.docID == docID}),
               let file = getFile(id: relation.key) {
                return file
            }
        }
        return nil
    }
    
    // Получение файла по id файла
    class func getFile(fileID: UUID) -> File? {
        getFile(id: fileID)
    }
    
    // Получение всех файлов по типу отношения и id сущности
    class func getFiles(type: RelationType, entityID: UUID) -> [File] {
        var files = [File]()
        for relation in getAllRelations() {
            if relation.value.contains(where: {$0.type == type && $0.entityID == entityID}),
               let file = getFile(id: relation.key) {
                files.append(file)
            }
        }
        return files
    }
    
    // Назначение файлу связи и записываем его в память, если он еще не записан
    class func add(files: [File], type: RelationType, entityID: UUID) {
        var allRelations = getAllRelations()
        for file in files {
            if let relations = allRelations[file.id] {
                if !relations.contains(where: { $0.type == type }) {
                    allRelations[file.id]?.append(Relation(docID: file.doc.id, entityID: entityID, type: type))
                }
            } else {
                for relations in allRelations {
                    if relations.value.contains(where: { $0.docID == file.doc.id }) {
                        if !relations.value.contains(where: { $0.type == type }) {
                            allRelations[relations.key]?.append(Relation(docID: file.doc.id, entityID: entityID, type: type))
                        }
                    } else {
                        allRelations[file.id] = [Relation(docID: file.doc.id, entityID: entityID, type: type)]
                        save(file: file)
                    }
                }
            }
        }
        save(relations: allRelations)
    }
    
    // Удаление файлов по метаданным и отношению к сущности
    class func delete(docs: [Doc], type: RelationType, entityID: UUID) {
        var allRelations = getAllRelations()
        for doc in docs {
            for relations in allRelations {
                if relations.value.contains(where: {$0.docID == doc.id }) {
                    allRelations[relations.key] = relations.value.filter({!($0.type == type && $0.entityID == entityID)})
                    if allRelations[relations.key]!.isEmpty {
                        delete(id: relations.key)
                    }
                }
            }
        }
        save(relations: allRelations)
    }
    
    // Удаление файлов по отношению к сущности
    class func delete(files: [File], type: RelationType, entityID: UUID) {
        var allRelations = getAllRelations()
        for file in files {
            for relations in allRelations {
                if relations.value.contains(where: { $0.docID == file.doc.id }) ||
                    relations.key == file.id {
                    allRelations[relations.key] = relations.value.filter({!($0.type == type && $0.entityID == entityID)})
                    if allRelations[relations.key]!.isEmpty {
                        delete(id: relations.key)
                    }
                }
            }
        }
        save(relations: allRelations)
    }
    
    // Удаление всех файлов, привязанных к данной сущности
    class func deleteAllFiles(type: RelationType, entityID: UUID) {
        let files = getFiles(type: type, entityID: entityID)
        delete(files: files, type: type, entityID: entityID)
    }
    
    
    // НИЖНИЙ УРОВЕНЬ. Внутренние функции
    
    // Получение файловой таблицы: id всех вайлов и их отношения
    private class func getAllRelations() -> [UUID: [Relation]] {
        var relations = [UUID: [Relation]]()
        if let data = UserDefaults.standard.value(forKey:"Relations") as? Data {
            if let decode = try? PropertyListDecoder().decode([UUID: Array<Relation>].self, from: data) {
                relations = decode
            }
        }
        return relations
    }
    
    // Сохранение файловой таблицы
    private class func save(relations: [UUID: [Relation]]) {
        UserDefaults.standard.set(try? PropertyListEncoder().encode(relations), forKey:"Relations")
    }
    
    // Получение файла из памяти телефона по id
    private class func getFile(id: UUID) -> File? {
        let url = path.appendingPathComponent("\(id).\(ext)")
        do {
            let data = try Data(contentsOf: url)
            let file = try JSONDecoder().decode(File.self, from: data)
            return file
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    // Сохранение файла в память телефона
    private class func save(file: File) {
        let url = path.appendingPathComponent("\(file.id).skf")
        do {
            let data = try JSONEncoder().encode(file)
            try data.write(to: url)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    // Удаление файла из памяти телефона
    private class func delete(id: UUID) {
        let url = path.appendingPathComponent("\(id).skf")
        let manager = FileManager()
        do {
            try manager.removeItem(at: url)
        } catch {
            print(error.localizedDescription)
        }
    }
}



