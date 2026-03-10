from pyspark.sql import SparkSession
from pyspark.sql.functions import col, when, hour, date_format, count, round
import matplotlib.pyplot as plt
import seaborn as sns

# Инициализация Spark
spark = SparkSession.builder.appName("Lab1_Final").getOrCreate()

# Загрузка данных (путь внутри контейнера)
df = spark.read.option("header", "true").option("inferSchema", "true") \
    .csv("/home/jovyan/transaction_data.csv")

# Задание 1: Фильтрация
print("--- Топ-5 неудачных транзакций ---")
df.filter(col("Transaction Status") == "Failed").select("Sender Account ID", "Transaction Amount").show(5)

# Задание 2: Средний чек по времени (SQL)
df_time = df.withColumn("day_of_week", date_format(col("Timestamp"), "EEEE")) \
    .withColumn("hour_val", hour(col("Timestamp"))) \
    .withColumn("period", when((col("hour_val") >= 6) & (col("hour_val") < 12), "Morning")
                        .when((col("hour_val") >= 12) & (col("hour_val") < 18), "Day")
                        .otherwise("Evening"))

df_time.createOrReplaceTempView("transactions")
print("--- Средний чек по дням недели ---")
spark.sql("SELECT day_of_week, period, round(avg(`Transaction Amount`), 2) as avg_amount FROM transactions GROUP BY 1, 2").show()

# Задание 3: Визуализация
print("--- Генерация Heatmap ---")
pd_df = spark.sql("SELECT day_of_week, hour_val, count(*) as tx_count FROM transactions GROUP BY 1, 2").toPandas()
pivot = pd_df.pivot(index="day_of_week", columns="hour_val", values="tx_count").fillna(0)

plt.figure(figsize=(12, 6))
# vmax=150 сделает так, что всё, что выше 150, будет максимально темным, 
# и мы увидим разницу между остальными днями
sns.heatmap(pivot, annot=True, fmt='g', cmap="YlGnBu", vmax=150, cbar_kws={'label': 'Кол-во транзакций'})
plt.title("Bank Transactions Distribution")
plt.savefig("/home/jovyan/final_heatmap.png")
print("Готово! График сохранен в /home/jovyan/final_heatmap.png")

spark.stop()
