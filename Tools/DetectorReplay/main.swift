//
//  DetectorReplay — pasa viajes grabados por MotoCare (CSV) por el MISMO
//  CrashDetector que usa la app, para afinar los umbrales en el Mac sin volver
//  a rodar. No forma parte de la app: está fuera de la carpeta MotoCare/.
//
//  Uso, desde la raíz del repo:
//    swiftc -O MotoCare/CrashDetector.swift Tools/DetectorReplay/main.swift -o /tmp/detector-replay
//    /tmp/detector-replay [opciones] viaje-*.csv
//
//  Opciones (por defecto, los umbrales de la app):
//    --ignore-speed        modo prueba en casa (ignora la velocidad)
//    --impact-g N          impacto mínimo en g
//    --tumble N            giro mínimo de volteo en °/s
//    --min-speed N         velocidad previa mínima en km/h
//    --still-g N           aceleración máxima para contar como "quieto"
//    --still-rot N         giro máximo para contar como "quieto" (°/s)
//

import Foundation

var config = CrashDetector.Config()
var files: [String] = []
var args = Array(CommandLine.arguments.dropFirst())

/// Lee el valor numérico que sigue a una opción (o deja el que había).
func numericValue(after option: String, default current: Double) -> Double {
    guard !args.isEmpty, let value = Double(args.removeFirst()) else {
        print("⚠️ La opción \(option) necesita un número; se usa \(current).")
        return current
    }
    return value
}

while !args.isEmpty {
    let arg = args.removeFirst()
    switch arg {
    case "--ignore-speed": config.ignoreSpeed = true
    case "--impact-g": config.impactAccelerationG = numericValue(after: arg, default: config.impactAccelerationG)
    case "--tumble": config.tumbleRotationDegPerSec = numericValue(after: arg, default: config.tumbleRotationDegPerSec)
    case "--min-speed": config.minSpeedBeforeKmh = numericValue(after: arg, default: config.minSpeedBeforeKmh)
    case "--still-g": config.stillAccelerationG = numericValue(after: arg, default: config.stillAccelerationG)
    case "--still-rot": config.stillRotationDegPerSec = numericValue(after: arg, default: config.stillRotationDegPerSec)
    default: files.append(arg)
    }
}

guard !files.isEmpty else {
    print("Uso: detector-replay [--ignore-speed] [--impact-g N] [--tumble N] [--min-speed N] viaje.csv …")
    exit(1)
}

print(String(format: "Umbrales: impacto ≥ %.1f g o volteo ≥ %.0f °/s · velocidad previa ≥ %.0f km/h%@ · quieto < %.2f g y < %.0f °/s",
             config.impactAccelerationG, config.tumbleRotationDegPerSec, config.minSpeedBeforeKmh,
             config.ignoreSpeed ? " (IGNORADA: modo prueba en casa)" : "",
             config.stillAccelerationG, config.stillRotationDegPerSec))

for path in files {
    let name = URL(fileURLWithPath: path).lastPathComponent
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
        print("\n⚠️ No se pudo leer \(path)")
        continue
    }
    var lines = text.split(whereSeparator: \.isNewline)
    guard !lines.isEmpty else { continue }
    let header = lines.removeFirst().split(separator: ",").map(String.init)
    guard let it = header.firstIndex(of: "t_s"),
          let isp = header.firstIndex(of: "speed_kmh"),
          let iacc = header.firstIndex(of: "acc_mag_g"),
          let irot = header.firstIndex(of: "rot_mag_rads") else {
        print("\n⚠️ \(name): no tiene las columnas esperadas")
        continue
    }
    let needed = max(it, isp, iacc, irot)

    print("\n▶︎ \(name) (\(lines.count) muestras)")
    var detector = CrashDetector(config: config)
    var count = 0
    for line in lines {
        let f = line.split(separator: ",", omittingEmptySubsequences: false)
        guard f.count > needed,
              let t = Double(f[it]), let speed = Double(f[isp]),
              let acc = Double(f[iacc]), let rot = Double(f[irot]) else { continue }
        if let d = detector.process(t: t, speedKmh: speed, accelerationG: acc,
                                    rotationDegPerSec: rot * 180 / .pi) {
            count += 1
            print(String(format: "  🚨 Detección %d: impacto t=%.2f s → confirmada t=%.2f s | confianza %@ | pico %.1f g, %.0f °/s | velocidad previa %.0f km/h | quieto %.0f %%",
                         count, d.impactTime, d.detectedTime, d.confidence.rawValue,
                         d.peakAccelerationG, d.peakRotationDegPerSec, d.speedBeforeKmh, d.stillFraction * 100))
            detector.acknowledge()   // como si el motero respondiera "Estoy bien", para seguir analizando
        }
    }
    if detector.phase != .monitoring {
        print("  … la grabación acaba con el detector en fase \(detector.phase) (ventana sin completar)")
    }
    print("  Total: \(count) detección(es)")
}
