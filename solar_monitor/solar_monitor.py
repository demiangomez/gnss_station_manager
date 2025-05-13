#!/usr/bin/env python
import os
import pandas as pd
import matplotlib
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from datetime import datetime, timedelta
import matplotlib.dates as mdates

matplotlib.use('TkAgg')

# Function to get the filename for the current date
def get_file_path(file_location):
    # Get today's date in YYYY-MM-DD format
    yesterday_date = (datetime.today() - timedelta(days=1)).strftime('%Y-%m-%d')
    today_date = datetime.today().strftime('%Y-%m-%d')
    # Build the file path for today's CSV file
    file_path1 = file_location + f'_{yesterday_date}.csv'
    file_path2 = file_location + f'_{today_date}.csv'
    
    return file_path1, file_path2

# Function to load and clean CSV data
def load_data(file_path1, file_path2):
    
    try:
        df1 = pd.read_table(file_path1, sep=',', header=None, names=['Timestamp', 'status', 'NA2', 'Battery Voltage (V)', 'Battery net current (A)', 'Daily Yield (kWh)', 'Instantaneous Power (W)', 'Load Current (A)', 'NA3'])
        df2 = pd.read_table(file_path2, sep=',', header=None, names=['Timestamp', 'status', 'NA2', 'Battery Voltage (V)', 'Battery net current (A)', 'Daily Yield (kWh)', 'Instantaneous Power (W)', 'Load Current (A)', 'NA3'])

        df = pd.concat([df1, df2])
        
    except FileNotFoundError:
        try:
            
            # try to open today's file, but it might not be available yet
            df = pd.read_table(file_path2, sep=',', header=None, names=['Timestamp', 'status', 'NA2', 'Battery Voltage (V)', 'Battery net current (A)', 'Daily Yield (kWh)', 'Instantaneous Power (W)', 'Load Current (A)', 'NA3'])
        
        except FileNotFoundError:
            return
        
    df_cleaned = df.iloc[:, [0, 1, 3, 4, 5, 6, 7]].copy()  # Make an explicit copy to avoid the SettingWithCopyWarning
    df_cleaned.columns = ['Timestamp', 'status', 'Battery Voltage (V)', 'Battery net current (A)', 'Daily Yield (kWh)', 'Instantaneous Power (W)', 'Load Current (A)']
    df_cleaned['Timestamp'] = pd.to_datetime(df_cleaned['Timestamp'], format='%Y-%m-%d %H:%M:%S')  # Now safe to modify
    
    print(df_cleaned)
    
    return df_cleaned

# Function to update the plot
def update_plot(frame, fig, axs, file_location, line_voltage, line_yield, line_power, line_current, line_current_net):
    file_path1, file_path2 = get_file_path(file_location)
    df_cleaned_new = load_data(file_path1, file_path2)
    
    # Filter data for the last 24 hours
    last_timestamp = df_cleaned_new['Timestamp'].max()
    twenty_four_hours_ago = last_timestamp - pd.Timedelta(hours=24)
    df_last_24_hours = df_cleaned_new[df_cleaned_new['Timestamp'] >= twenty_four_hours_ago]
        
    print(f"Last Timestamp: {last_timestamp}")
    print(f"Number of records in last 24 hours: {len(df_last_24_hours)}")
    
    if len(df_last_24_hours) == 0:
        print("Warning: No data for the last 24 hours.")
        return line_voltage, line_yield, line_power, line_current
    
    # Update the data for each plot
    line_voltage.set_data(df_last_24_hours['Timestamp'], df_last_24_hours['Battery Voltage (V)'])
    line_yield.set_data(df_last_24_hours['Timestamp'], df_last_24_hours['Daily Yield (kWh)'])
    line_power.set_data(df_last_24_hours['Timestamp'], df_last_24_hours['Instantaneous Power (W)'])
    line_current.set_data(df_last_24_hours['Timestamp'], df_last_24_hours['Load Current (A)'])
    line_current_net.set_data(df_last_24_hours['Timestamp'], df_last_24_hours['Battery net current (A)'])

    # Update the last recorded data info
    timestamp_str = f"Last Timestamp: {last_timestamp.strftime('%Y-%m-%d %H:%M:%S')}"
    last_data_str = f"Battery Voltage: {df_last_24_hours['Battery Voltage (V)'].iloc[-1]} V, " \
                    f"Daily Yield: {df_last_24_hours['Daily Yield (kWh)'].iloc[-1]} kWh, " \
                    f"Instantaneous Power: {df_last_24_hours['Instantaneous Power (W)'].iloc[-1]} W, " \
                    f"Load Current: {df_last_24_hours['Load Current (A)'].iloc[-1]} A, " \
                    f"Charging state: {df_last_24_hours['status'].iloc[-1]}"
    
    plt.suptitle(f'{timestamp_str}\n{last_data_str}', fontsize=16)
    
    for ax in axs.flat:
        ax.relim()
        ax.autoscale_view()
    
    fig.canvas.draw()
    # plt.pause(0.1) # pause is needed to allow the figure to be redrawn
    
    return line_voltage, line_yield, line_power, line_current
    
def main(file_location):

    # plt.ion()  # Turn on interactive mode for live updates

    # Prepare the figure and axis for plotting
    fig, axs = plt.subplots(2, 2, figsize=(12, 10))
    mng = plt.get_current_fig_manager()
    mng.resize(*mng.window.maxsize())
    fig.suptitle('Monitoring Solar System Data', fontsize=16)

    # Set up the subplots for Battery Voltage, Daily Yield, Instantaneous Power, and Load Current
    axs[0, 0].set_title('Battery Voltage')
    axs[0, 1].set_title('Daily Yield')
    axs[1, 0].set_title('Instantaneous Power')
    axs[1, 1].set_title('Current')

    file_path1, file_path2 = get_file_path(file_location)
    df_cleaned_new = load_data(file_path1, file_path2)
    
    # Filter data for the last 24 hours
    last_timestamp = df_cleaned_new['Timestamp'].max()
    twenty_four_hours_ago = last_timestamp - pd.Timedelta(hours=24)
    df_last_24_hours = df_cleaned_new[df_cleaned_new['Timestamp'] >= twenty_four_hours_ago]
    
    # Line plots for each subplot
    line_voltage, = axs[0, 0].plot(df_last_24_hours['Timestamp'], df_last_24_hours['Battery Voltage (V)'], label='Battery Voltage (V)')
    line_yield, = axs[0, 1].plot(df_last_24_hours['Timestamp'], df_last_24_hours['Daily Yield (kWh)'], label='Daily Yield (kWh)')
    line_power, = axs[1, 0].plot(df_last_24_hours['Timestamp'], df_last_24_hours['Instantaneous Power (W)'], label='Instantaneous Power (W)')
    line_current, = axs[1, 1].plot(df_last_24_hours['Timestamp'], df_last_24_hours['Load Current (A)'], label='Load Current (A)')
    line_current_net, = axs[1, 1].plot(df_last_24_hours['Timestamp'], df_last_24_hours['Battery net current (A)'], label='Battery Net Current (A)')

    # Set limits and labels for each subplot
    for ax in axs.flat:
        # ax.set_xlabel('Timestamp')
        # ax.set_ylabel('Value')
        ax.grid(True, linestyle='--', linewidth=0.5, alpha=0.7)

    # Set the x-axis to handle timestamps properly
    axs[0, 0].xaxis.set_major_locator(mdates.HourLocator(interval=2))  # Set major ticks for each hour
    axs[0, 0].xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))  # Format as HH:MM
    axs[0, 0].set_ylabel('[V]')
    axs[0, 1].xaxis.set_major_locator(mdates.HourLocator(interval=2))
    axs[0, 1].xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
    axs[0, 1].set_ylabel('[kWh]')
    axs[1, 0].xaxis.set_major_locator(mdates.HourLocator(interval=2))
    axs[1, 0].xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
    axs[1, 0].set_ylabel('[W]')
    axs[1, 1].xaxis.set_major_locator(mdates.HourLocator(interval=2))
    axs[1, 1].xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
    axs[1, 1].legend(loc="upper left")
    axs[1, 1].set_ylabel('[A]')
    
    # Rotate the x-axis labels for better readability
    for ax in axs.flat:
        plt.setp(ax.get_xticklabels(), rotation=45, ha="right")
    
    # Set up the animation to update every 30 seconds
    ani = FuncAnimation(fig, update_plot, fargs=(fig, axs, file_location, line_voltage, line_yield, line_power, line_current, line_current_net),
                        interval=3000, blit=True, cache_frame_data=False)

    # Show the plot
    plt.tight_layout()
    plt.show()

if __name__ == "__main__":

    # parse the config file
    cfg = []

    try:
        with open('/usr/local/bin/solarMonitor/config.txt', 'rt', encoding='utf-8', errors='ignore') as f:
            cfg = f.readlines()
    except FileNotFoundError:
        try:
            with open('./config.txt', 'rt', encoding='utf-8', errors='ignore') as f:
                cfg = f.readlines()
        except FileNotFoundError:
            print(' >> No configuration file found!')
            exit(1)

    # Argument parsing for file location
    for c in cfg:
        if c.split('=')[0].lower() in ('output_file',):
            file_location=c.split('=')[1].strip().replace('"', '')
    
    # Run the monitoring program
    main(file_location)

