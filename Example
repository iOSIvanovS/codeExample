// ПРИМЕР ИСПОЛЬЗОВАНИЯ

let file = File(id: UUID(), doc: Doc(id: UUID(), name: "Документ", ext: "doc"), data: Data())

let id = UUID()

// Удалить файл, который является чертежом с ID = id
FileSystem.delete(files: [file], type: .drawings, entityID: id)

// получить все фото по инспекции ID = id
let photos = FileSystem.getFiles(type: .inspectionPhotos, entityID: id)

// Удалить все документы по стройке с ID = id
FileSystem.deleteAllFiles(type: .objectDocs, entityID: id)
