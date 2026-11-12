"""Gera os efeitos sonoros provisórios do BIOWAR: FRONTLINE em assets/audio/sfx/.

Os sons são sintetizados (ondas, ruído filtrado e envelopes), sem arquivos de terceiros.
Uso, a partir da pasta do projeto:  python tools/generate_sfx.py
Só usa a biblioteca padrão do Python. Mesmo resultado a cada execução (semente fixa).
"""

import math
import os
import random
import struct
import wave

RATE = 44100
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")
rng = random.Random(1914)


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def tone(freq_start, freq_end, seconds, wave_kind="sine", volume=0.5, attack=0.005, release=None):
    """Tom com glissando linear de freq_start a freq_end e envelope ataque/decaimento."""
    n = int(RATE * seconds)
    release = seconds * 0.6 if release is None else release
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        freq = freq_start + (freq_end - freq_start) * (i / max(n - 1, 1))
        phase += 2 * math.pi * freq / RATE
        if wave_kind == "sine":
            s = math.sin(phase)
        elif wave_kind == "square":
            s = 1.0 if math.sin(phase) >= 0 else -1.0
            s *= 0.5
        elif wave_kind == "tri":
            s = 2 / math.pi * math.asin(math.sin(phase))
        else:
            raise ValueError(wave_kind)
        out.append(s * volume * envelope(t, seconds, attack, release))
    return out


def noise(seconds, volume=0.5, smoothing=0.0, attack=0.002, release=None):
    """Ruído branco passado por um filtro passa-baixa simples (smoothing de 0 a 0,99)."""
    n = int(RATE * seconds)
    release = seconds * 0.8 if release is None else release
    out = []
    last = 0.0
    for i in range(n):
        t = i / RATE
        raw = rng.uniform(-1.0, 1.0)
        last = last * smoothing + raw * (1.0 - smoothing)
        out.append(last * volume * envelope(t, seconds, attack, release))
    return out


def envelope(t, total, attack, release):
    if t < attack:
        return t / attack
    start_release = total - release
    if t > start_release:
        return max(0.0, (total - t) / release)
    return 1.0


def mix(*tracks):
    length = max(len(t) for t in tracks)
    out = [0.0] * length
    for track in tracks:
        for i, s in enumerate(track):
            out[i] += s
    return out


def concat(*tracks):
    out = []
    for track in tracks:
        out.extend(track)
    return out


def write(name, samples, peak=0.8):
    top = max(abs(s) for s in samples) or 1.0
    scale = peak / top
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name + ".wav")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples))
    print("gerado", os.path.normpath(path))


def main():
    # Interface
    write("select", tone(1400, 1600, 0.05, "tri", attack=0.002), peak=0.45)
    write("order_move", concat(tone(700, 700, 0.04, "tri"), tone(1050, 1050, 0.06, "tri")), peak=0.45)
    write("order_attack", concat(tone(520, 480, 0.05, "square"), tone(390, 360, 0.08, "square")), peak=0.4)

    # Combate
    write("attack_player", mix(noise(0.09, smoothing=0.85), tone(180, 90, 0.09, "sine", volume=0.6)), peak=0.5)
    write("attack_enemy", mix(noise(0.07, smoothing=0.6), tone(420, 260, 0.07, "sine", volume=0.3)), peak=0.4)
    write("death_enemy", mix(noise(0.28, smoothing=0.75, volume=0.6), tone(500, 70, 0.28, "sine", volume=0.7)), peak=0.6)
    write("death_player", mix(noise(0.4, smoothing=0.9, volume=0.5), tone(220, 55, 0.4, "tri", volume=0.8)), peak=0.65)

    # Habilidades
    write("ability_speed", mix(noise(0.4, smoothing=0.5, volume=0.4, attack=0.15), tone(300, 1300, 0.4, "sine", volume=0.4, attack=0.1)), peak=0.5)
    shimmer = mix(*[tone(f, f * 1.01, 0.6, "sine", volume=0.25, attack=0.08) for f in (523, 659, 784, 1046)])
    write("ability_cytokine", shimmer, peak=0.5)

    # Missão
    write("focus_controlled", concat(tone(784, 784, 0.12, "tri"), tone(1046, 1046, 0.3, "tri")), peak=0.55)
    write("alert", concat(tone(880, 880, 0.12, "square"), silence(0.08), tone(880, 880, 0.12, "square")), peak=0.4)
    notes_up = [523, 659, 784, 1046]
    write("victory", concat(*[tone(f, f, 0.16, "tri") for f in notes_up[:-1]], tone(1046, 1046, 0.6, "tri")), peak=0.6)
    notes_down = [392, 349, 311, 262]
    write("defeat", concat(*[tone(f, f * 0.98, 0.25, "tri") for f in notes_down[:-1]], tone(262, 240, 0.8, "tri")), peak=0.6)

    # Fuzil (D013). Gerado por último para não mudar o sorteio do ruído dos sons anteriores.
    shot = mix(noise(0.12, smoothing=0.3, volume=0.9, attack=0.001, release=0.11), tone(140, 60, 0.12, "sine", volume=0.7, attack=0.001))
    write("rifle_shot", shot, peak=0.55)

    # Escudo de bioenergia (D015). Também no fim, pelo mesmo motivo.
    zap = mix(tone(900, 1500, 0.14, "sine", volume=0.5, attack=0.002), noise(0.14, smoothing=0.2, volume=0.25, attack=0.002))
    write("shield_hit", zap, peak=0.45)
    write("shield_break", mix(tone(1200, 200, 0.35, "tri", volume=0.6), noise(0.35, smoothing=0.5, volume=0.4)), peak=0.55)


if __name__ == "__main__":
    main()
