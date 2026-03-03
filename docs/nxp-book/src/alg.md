## Diagrama funcționare:

        ↓
[Algoritm intern detectare linii Pixy2]  
        ↓  
[Extragerea vectorilor de direcție]  
        ↓  
[Determinarea erorii de abatere laterală și a erorii unghiulare]  
        ↓  
[Filtrare pentru reducerea zgomotului]  
        ↓  
[Aplicarea controlerului Stanley în format fixed-point]  
        ↓  
[Generarea semnalului PWM pentru servomotor]  


---

## Raționamentul din spatele alegerii algoritmului

## Descriere funcționare algoritm

În continuare ne vom folosi de algoritmul introdus de Jozsef Suto pentru urmărirea traseului, cu mențiunea că, diferit față de articolul scris de acesta — unde procesarea imaginii pentru detectarea liniilor se face folosind transformata Hough — noi ne vom folosi de funcțiile puse la dispoziție de camera Pixy2 pentru a detecta aceste linii.

Liniile ce trebuie urmate sunt descrise fiecare de 2 puncte în coordonate carteziene.

Ecuația dreptei:

\\\[
y = mx + b \tag{1}
\\\]

Din (1) determinăm panta și ordonata la origine curentă:

\\[
m_{curr} = \frac{y_2 - y_1}{x_2 - x_1} \tag{2}
\\]

\\[
b_{curr} = y_2 - m_{curr} \cdot x_2 \tag{3}
\\]

Aceste linii ce ne determină drumul au un unghi limitat, astfel putem defini un filtru unde unghiul \\(\alpha\\) dintre segmentul liniei și ordonată aparține intervalului:

\\[
\left[\frac{\pi}{18}, \frac{4\pi}{9}\right]
\\]

\\(\alpha\\) poate fi calculată din pantă după formula:

\\[
\alpha = \left| \frac{180}{\pi} \cdot \arctan(m) \right|
\\]

Alegem \\(p^i_1\\) ca fiind punctul liniei de bandă localizat la baza imaginii. Astfel impunem condiția:

\\[
y_1 \ge 0.4 \cdot y_{c1}
\\]

Liniile ce nu îndeplinesc acest criteriu nu vor fi luate în considerare.

În practică, banda va fi descrisă de până la două linii, cu proprietatea fundamentală că cea din stânga va avea o pantă negativă, iar cea din dreapta o pantă pozitivă.

---

## Detecția benzii

Algoritmul are în fața sa 3 cazuri posibile care descriu în egală măsură o bandă:

- Linii cu pantă pozitivă și negativă  
- Linii doar cu pantă pozitivă sau negativă (cel mai întâlnit caz pentru noi, datorat dimensiunilor reduse ale mașinii)  
- Fără linii de ghidaj (caz întâlnit de obicei în intersecții)  

### Cazul cu două linii

Dacă ambele tipuri apar, algoritmul va alege perechea cea mai favorabilă după condiția:

\\[
\min \left( 0.7(d_n + d_p) + 0.3 \cdot d_c \right) \tag{5}
\\]

Unde:

- \\(d_c\\) reprezintă distanța euclidiană dintre \\(p_c\\) și \\(c\\)
- \\(p_c\\) este punctul central al liniei ce conectează bazele celor două segmente curente
- \\(c\\) este referința predefinită a centrului drumului
- \\(d_n\\) și \\(d_p\\) sunt distanțele euclidiene dintre liniile negative/pozitive și media ponderată anterioară a liniilor benzii

Pentru aceste calcule folosim:

\\[
x_i = \frac{y_i - b_i}{m_i} \tag{6}
\\]

### Cazul cu o singură linie

Dacă doar o linie este disponibilă pentru determinarea benzii (fie cu pantă pozitivă sau negativă), se va alege aceea care satisface criteriul:

\\[
\min \left( 0.7 \cdot d_{np} + 0.3 \cdot d_{p1} \right) \tag{7}
\\]

Unde:

- \\(d_{p1}\\) este distanța euclidiană dintre \\(c\\) și baza liniei testate  
- \\(d_{np}\\) reprezintă distanța dintre linia delimitatoare curentă și cea anterioară cu aceeași pantă  

---

## Modul de calcul al unghiului de viraj

Se mențin aceleași 3 cazuri.

### Cazul cu două linii

Unghiul curent de viraj \\(\theta_{curr}\\) este:

\\[
\theta_{curr} = 0.8 \cdot \theta_{vp} + 0.2 \cdot \theta_d \tag{8}
\\]

Din cauza perspectivei tridimensionale proiectate în plan bidimensional, liniile paralele se întâlnesc într-un punct de fugă (vanishing point – vp).

Acesta este determinat prin intersecția liniilor:

\\[
x_{vp} = \frac{b_j - b_i}{m_i - m_j}
\\]

\\[
y_{vp} = m_i \cdot x_{vp} + b_i \tag{9}
\\]

\\(\theta_{vp}\\) este unghiul dintre vectorii \\((c_1, c_2)\\) și \\((c_1, vp)\\).

\\[
\theta_{vp} =
\begin{cases}
-\frac{180}{\pi} \arccos\left( \frac{a \cdot b}{\|a\| \|b\|} \right), & x_{vp} > x_{c2} \\
\frac{180}{\pi} \arccos\left( \frac{a \cdot b}{\|a\| \|b\|} \right), & \text{altfel}
\end{cases}
\\]

Algoritmul ia în considerare și distanța dintre \\(c_1\\) și liniile benzii.

\\[
\theta_d =
\begin{cases}
-60 \cdot \frac{d_{px} - d_{nx}}{d_{px} + d_{nx}}, & d_{px} > d_{nx} \\
60 \cdot \frac{d_{nx} - d_{px}}{d_{px} + d_{nx}}, & \text{altfel}
\end{cases}
\tag{11}
\\]

---

### Cazul cu o singură linie

\\[
\theta_t = \theta_{t-1} + \theta_{\delta}
\\]

Pentru pantă negativă:

\\[
\theta_{\delta} =
\begin{cases}
60 \cdot \frac{d_t - d_{t-1}}{d_{t-1}}, & d_t > d_{t-1} \\
-60 \cdot \frac{d_{t-1} - d_t}{d_{t-1}}, & \text{altfel}
\end{cases}
\tag{13}
\\]

Pentru pantă pozitivă:

\\[
\theta_{\delta} =
\begin{cases}
-60 \cdot \frac{d_t - d_{t-1}}{d_{t-1}}, & d_t > d_{t-1} \\
60 \cdot \frac{d_{t-1} - d_t}{d_{t-1}}, & \text{altfel}
\end{cases}
\tag{14}
\\]

---

## Filtrare temporală

Constante:

\\[
w_1 = 0.1, \quad w_2 = 0.05
\\]

\\[
\theta_t = w_1 \cdot \theta_{curr} + (1 - w_1) \cdot \theta_{t-1} \tag{15}
\\]

\\[
m^i_t = w_2 \cdot m^i_{curr} + (1 - w_2) \cdot m^i_{t-1}
\\]

\\[
b^i_t = w_2 \cdot b^i_{curr} + (1 - w_2) \cdot b^i_{t-1} \tag{16}
\\]

*Unde \\(\theta_t\\) va controla unghiul servoului simulat*

---

## MORE_TO_BE_ADDED

---

## Referințe

- [REAL-TIME LANE LINE TRACKING ALGORITHM TO MINI VEHICLES - Jozsef Suto](https://reference-global.com/article/10.2478/ttj-2021-0036)  
- [Real-Time Deterministic Lane Detection on CPU-Only Embedded Systems via Binary Line Segment Filtering - Shang-En Tsai et al.](https://www.preprints.org/frontend/manuscript/2af34e02773a1d1839e8234f3fa531b4/download_pub?)  
- [Autonomous Automobile Trajectory Tracking for Off-Road Driving - Hoffmann et al.](https://ai.stanford.edu/~gabeh/papers/hoffmann_stanley_control07.pdf?)  
- [Kalman filter](https://en.wikipedia.org/wiki/Kalman_filter?)  
- [Realtime Road Lane Detection - IRJET](https://www.irjet.net/archives/V9/i5/IRJET-V9I5488.pdf?)  
