# MAC unit 
This unit is used to performs an hardware multiply and accumulate operation. The main requirements are: 
- INT8 data format (FP16 may be considerated in future works if enough area).
- Radix-4 Booth encorder for generating patials (Radix-8 may be considered only if does not introduce too much complexity).
- Dadda tree for the partial sums (Wallace tree generates too much complexity and area).
- Carry Look-ahead or final sum (carry-skip may be considered to reduce area).

The MAC unit should be small enough to achieve a large enough systolic array and process data with high troughput.
<p>
  <img width="690" height="382" alt="MUL" src="https://github.com/user-attachments/assets/54da51b6-dd85-47f3-8177-650571911ae3" />
</p>
