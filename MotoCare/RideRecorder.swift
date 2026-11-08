//
//  RideRecorder.swift
//  MotoCare
//
//  Graba los datos de cada viaje en un CSV dentro de Documents/RideLogs para
//  analizarlos después y fijar los umbrales del detector de accidentes
//  (MVP paso 2). Sin coordenadas GPS, a propósito: el archivo no revela por
//  dónde circula el motero ni dónde vive.
//

import Foundation

final class RideRecorder {

    /// `det_state`: fase del detector de accidentes (0 vigilando, 1 impacto, 2 observando, 3 detectado).
    static let header = "t_s,speed_kmh,acc_x_g,acc_y_g,acc_z_g,acc_mag_g,grav_x_g,grav_y_g,grav_z_g,rot_x_rads,rot_y_rads,rot_z_rads,rot_mag_rads,roll_deg,pitch_deg,yaw_deg,marker,det_state"

    let fileURL: URL
    private var handle: FileHandle?

    /// Crea el archivo del viaje y escribe la cabecera.
    init(startDate: Date = Date()) throws {
        let folder = URL.documentsDirectory.appending(path: "RideLogs", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        // en_US_POSIX: el nombre del archivo no depende del idioma ni del calendario del iPhone.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        fileURL = folder.appending(path: "viaje-\(formatter.string(from: startDate)).csv")

        try Data((Self.header + "\n").utf8).write(to: fileURL, options: .withoutOverwriting)
        handle = try FileHandle(forWritingTo: fileURL)
        _ = try handle?.seekToEnd()
    }

    /// Añade un lote de filas ya formateadas (una por muestra).
    func append(_ lines: [String]) {
        guard let handle, !lines.isEmpty else { return }
        let chunk = lines.joined(separator: "\n") + "\n"
        // Un fallo puntual de escritura no debe tumbar el viaje: se pierde solo ese lote.
        try? handle.write(contentsOf: Data(chunk.utf8))
    }

    /// Cierra el archivo y devuelve su URL para compartirlo.
    func finish() -> URL {
        try? handle?.close()
        handle = nil
        return fileURL
    }
}
