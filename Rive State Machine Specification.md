## **Rive State Machine Specification**

Flutter berinteraksi dengan aset visual melalui Rive State Machine binding. Seluruh kalkulasi animasi dijalankan pada runtime Rive, bukan melalui Flutter widget rebuild.

### **5.1 Chrono Dial (`chrono_dial.riv`)**

* **State Machine Name**: `SM_ChronoDial`  
* **Input Parameters**:  
  * `targetMinutes` (Number): Durasi target yang dipilih (Rentang: `0.0` \- `90.0`).  
  * `progressPercent` (Number): Nilai rasio waktu tersisa (Rentang: `0.0` \- `1.0`).  
  * `isRunning` (Boolean): Status aktif/jeda timer.  
  * `pressTrigger` (Trigger): Animasi mekanik penekanan tombol fisik samping.  
* **Event Callbacks (Rive \-\> Flutter)**:  
  * `onMinuteTick`: Mengirim sinyal setiap jarum melewati penanda 1 menit untuk trigger haptic getar.

    ### **5.2 Receipt Runner (`receipt_runner.riv`)**

* **State Machine Name**: `SM_ReceiptRunner`  
* **Input Parameters**:  
  * `feedPaper` (Trigger): Mengeluarkan lembaran struk baru dari slot dispenser.  
  * `tearProgress` (Number): Tingkat robekan kertas dari gestur drag horizontal pengguna (Rentang: `0.0` \- `1.0`).  
  * `stampTrigger` (Trigger): Menjatuhkan stempel cap `[DONE]` ke atas kertas struk.  
  * `ejectPaper` (Trigger): Melepaskan dan menerbangkan kertas yang sudah robek penuh keluar kanvas.

    ### **5.3 Vinyl Player (`vinyl_deck.riv`)**

* **State Machine Name**: `SM_VinylDeck`  
* **Input Parameters**:  
  * `needleOnRecord` (Boolean): Posisi jarum (True \= di atas piringan, False \= docking).  
  * `turntableSpeed` (Number): Kecepatan perputaran piringan (`0.0` berhenti, `1.0` kecepatan standar).  
  * `vinylStyleIndex` (Number): Indeks varian warna label tengah piringan hitam (`0` s/d `3`).  
    

