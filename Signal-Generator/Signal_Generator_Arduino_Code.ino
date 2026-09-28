#include <LiquidCrystal.h>   
#include <PWM.h>             
#include <math.h>            

const int rs = 14, en = 15, d4 = 4, d5 = 3, d6 = 6, d7 = 7;
LiquidCrystal lcd(rs, en, d4, d5, d6, d7);

const int Encoder_CLK = 11;    
const int Encoder_DT = 12;     
const int Encoder_Switch = 10; 

const int signal_pin = 9;      
const int sine_pin = 5;        
const int POT_pin = A2;        

int32_t frequency = 1000;      
const int32_t lower_level_freq = 1;    
const int32_t upper_level_freq = 10000000;  

int Previous_CLK;             
int multiplier = 1;            
double angle = 0;              
double increment = 0.2;        

const int filter_window_size = 10;  // Number of values for moving average
int smoothing_buffer[filter_window_size]; 
int buffer_index = 0;
long sum = 0;  

void setup() {
  lcd.begin(16, 2);           
  lcd.print("Waveform");
  lcd.setCursor(0, 1);
  lcd.print("Generator ");
  delay(2000);
  lcd.clear();
  lcd.print("Freq:1000 Hz");
  lcd.setCursor(0, 1);
  lcd.print("Inc. by: 1 ");
  Serial.begin(9600);
  InitTimersSafe();           
  pinMode(Encoder_CLK, INPUT_PULLUP);
  pinMode(Encoder_DT, INPUT_PULLUP);
  pinMode(Encoder_Switch, INPUT_PULLUP);
  Previous_CLK = digitalRead(Encoder_CLK);
  SetPinFrequencySafe(signal_pin, frequency);
  pwmWriteHR(signal_pin, 32768);  

  // Initialize smoothing buffer
  for (int i = 0; i < filter_window_size; i++) {
    smoothing_buffer[i] = 0;
  }
}

void loop() {
  int current_CLK = digitalRead(Encoder_CLK);
  if (current_CLK != Previous_CLK) {
    if (digitalRead(Encoder_DT) != current_CLK) {
      frequency += multiplier;  
    } else {
      frequency -= multiplier;  
    }
    frequency = constrain(frequency, lower_level_freq, upper_level_freq); 
    SetPinFrequencySafe(signal_pin, frequency);  
    pwmWriteHR(signal_pin, 32768);               
    lcd.setCursor(0, 0);
    lcd.print("Freq:      Hz");
    lcd.setCursor(5, 0);
    lcd.print(frequency);
    lcd.print("   ");  
  }
  if (digitalRead(Encoder_Switch) == LOW) {
    multiplier *= 10;
    if (multiplier > 10000) multiplier = 1;
    lcd.setCursor(0, 1);
    lcd.print("Inc. by:    ");
    lcd.setCursor(8, 1);
    lcd.print(multiplier);
    lcd.print("   ");  
    delay(500);  
    while (digitalRead(Encoder_Switch) == LOW);  
  }
  Previous_CLK = current_CLK;
  generate_sine();
}

void generate_sine() {
  double sineValue = sin(angle);  
  sineValue *= 255;  
  int plot = map(sineValue, -255, +255, 0, 255); 

  // Smooth the signal using moving average
  sum -= smoothing_buffer[buffer_index];  // Subtract the oldest value
  smoothing_buffer[buffer_index] = plot; // Store the new value
  sum += smoothing_buffer[buffer_index]; // Add the new value
  buffer_index = (buffer_index + 1) % filter_window_size; // Move to the next buffer slot
  int smoothed_plot = sum / filter_window_size; // Compute the average
  
  analogWrite(sine_pin, smoothed_plot); // Output the smoothed signal
  angle += increment;
  if (angle > 2 * PI) angle = 0;  
}
